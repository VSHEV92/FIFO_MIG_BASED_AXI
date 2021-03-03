// ---------------------------------------------------
// функция для поиска пути расположения тестового файла
function automatic string find_file_path(input string file_full_name);
    int str_len = file_full_name.len();
    str_len--;
    while (file_full_name.getc(str_len) != "/") begin
        str_len--;
    end
    return file_full_name.substr(0, str_len); 
endfunction


// ---------------------------------------------------
// --------------  AXIS интерфейс  -------------------
// ---------------------------------------------------
interface AXIS_intf
    #(
        parameter int TDATA_WIDTH = 128
    )
    (
        input bit aclk,
        input bit aresetn 
    );

    bit tready;
    bit tvalid;
    bit [TDATA_WIDTH-1:0] tdata;
    
    modport Master (
        input  aclk, aresetn,
        output tdata, tvalid,
        input  tready
    );

    modport Slave (
        input  aclk, aresetn,
        input  tdata, tvalid,
        output tready
    );

endinterface

// ---------------------------------------------------
// -----------------  Транзакция  --------------------
// ---------------------------------------------------
class Transaction
#(
    parameter int TDATA_WIDTH = 128   // размер шины данных
);
    rand logic [TDATA_WIDTH-1:0] data;
    int unsigned count;

    // выдача данных транзакции
    function logic [TDATA_WIDTH-1:0] get_data();
        return data;        
    endfunction

    // выдача номера транзакции
    function int unsigned get_count();
        return count;        
    endfunction

    // запись данных транзакции
    function void set_data(logic [TDATA_WIDTH-1:0] data);
        this.data = data;        
    endfunction

    // запись номера транзакций
    function void set_count(int count);
        this.count = count;    
    endfunction    
    
    // запись в лог 
    function void print(string tag="");
        $display("%s: time = %t, transaction number = %0d, value = %h", tag, $time, count, data);
    endfunction

endclass

// ---------------------------------------------------
// --------------  Генератор данных  -----------------
// ---------------------------------------------------
class Generator
#(
    parameter int TDATA_WIDTH = 128
);
    int unsigned delay;     // случайная задержка генератор
    int gen_max_delay_ns;   // максимальная задержка генератора в нс
    Transaction #(TDATA_WIDTH) trans;
    
    mailbox mb_driver;
    mailbox mb_scoreboard;
    
    //конструктор класс
    function new(int gen_max_delay_ns);
        this.gen_max_delay_ns = gen_max_delay_ns;
    endfunction

    // передача случайных данных в mailbox
    task send_data_to_mb(int count);
        trans = new;
        trans.randomize();
        trans.set_count(count);
        delay = $urandom_range(0, gen_max_delay_ns);
        # delay; // случайная задержка
        mb_driver.put(trans);
        mb_scoreboard.put(trans);
        trans.print("Generator");      
    endtask

    // создать заданное число транзакций
    task run(input int trans_numb);
        for (int count = 1; count <= trans_numb; count++)
            send_data_to_mb(count);    
        $display("Generator Done.");    
    endtask

endclass    

// ---------------------------------------------------
// ------------------  Драйвер  ----------------------
// ---------------------------------------------------
class Driver
#(
    parameter int TDATA_WIDTH = 128   // размер шины данных
);
    mailbox mb_driver;
    Transaction #(TDATA_WIDTH) trans;
    virtual AXIS_intf #(TDATA_WIDTH) axis;
    
    //конструктор класс
    function new();
        trans = new;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb);
        bit have_data = 0;
        int count = 0;
        forever begin
            wait (axis.aresetn);

            @(posedge axis.aclk)
            if (!(axis.tvalid  && !axis.tready)) begin
                if(mb_driver.try_get(trans)) begin
                    axis.tvalid <= 1'b1;
                    axis.tdata <= trans.get_data();
                    trans.print("Driver");
                end else
                    axis.tvalid <= 1'b0;
                if(axis.tready && axis.tvalid) begin
                    count++;  // увеличение счетчика переданных данных
                    if (count == trans_numb) // завершение работы драйвера
                        break;   
                end
            end       
        end
        axis.tvalid <= 1'b0;
        $display("Driver Done.");        
    endtask

endclass


// ---------------------------------------------------
// ------------------  Монитор  ----------------------
// ---------------------------------------------------
class Monitor
#(
    parameter int TDATA_WIDTH = 128   // размер шины данных
);
    mailbox mb_monitor;
    Transaction #(TDATA_WIDTH) trans;
    virtual AXIS_intf #(TDATA_WIDTH) axis;
    int unsigned delay;     // случайная задержка монитора
    int mon_max_delay_ns;   // максимальная задержка монитора в нс
    
    //конструктор класс
    function new(int mon_max_delay_ns);
        this.mon_max_delay_ns = mon_max_delay_ns;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb);
        int count = 0;
        forever begin
            wait (axis.aresetn);
            @(posedge axis.aclk)
            if(!axis.tready) 
                axis.tready <= 1;    
            // если данные валидны, скадем их в mailbox
            else if(axis.tvalid) begin
                axis.tready <= 0;
                count++;
                trans = new;
                trans.set_data(axis.tdata);
                trans.set_count(count);
                trans.print("Monitor");
                delay = $urandom_range(0, mon_max_delay_ns);
                # delay; // случайная задержка
                mb_monitor.put(trans);
                if (count == trans_numb) // завершение работы драйвера
                    break;   
            end           
        end
        axis.tready <= 1'b0;
        $display("Monitor Done.");
    endtask

endclass

// ---------------------------------------------------
// ------------  Вычисление результата  --------------
// ---------------------------------------------------
class Scoreboard
#(
    parameter int TDATA_WIDTH = 128   // размер шины данных
);
    int test_pass = 1;
    mailbox mb_monitor;
    mailbox mb_driver;
    Transaction #(TDATA_WIDTH) monintor_trans;
    Transaction #(TDATA_WIDTH) driver_trans;
    
    //конструктор класс
    function new();
        monintor_trans = new;
        driver_trans = new;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb);
        automatic int f_logs; 
        automatic string file_path = find_file_path(`__FILE__);
        
        repeat(trans_numb) begin
            // получаем данные от монитора
            mb_monitor.get(monintor_trans);
            monintor_trans.print("Score Monitor");
            
            // получаем данные от драйвера
            mb_driver.get(driver_trans);
            driver_trans.print("Score Driver");

            if (monintor_trans.get_count() != driver_trans.get_count()) begin // проверка порядка транзакций
                f_logs = $fopen({file_path, "../../log_fifo_mig_based_tests/Test_Logs.txt"}, "a");
                $display("Wrong transctions order! Tx number: %0d. Rx number: %0d.", driver_trans.get_count(), monintor_trans.get_count());
                $fdisplay(f_logs, "Wrong transctions order! Rx number: %0d. Tx number: %0d.", driver_trans.get_count(), monintor_trans.get_count());
                $fclose(f_logs);
                test_pass = 0;
            end
            else if (monintor_trans.data != driver_trans.data) begin // проверка данных транзакций
                f_logs = $fopen({file_path, "../../log_fifo_mig_based_tests/Test_Logs.txt"}, "a");
                $display("Wrong transction data! Number %3d. Tx value: %h. Rx value: %h.", driver_trans.get_count(), driver_trans.get_data(), monintor_trans.get_data());
                $fdisplay(f_logs, "Wrong transction data! Number %3d. Tx value: %h. Rx value: %h.", driver_trans.get_count(), driver_trans.get_data(), monintor_trans.get_data());
                $fclose(f_logs);
                test_pass = 0;
            end
        end
        $display("Scoreboard Done.");        
    endtask

endclass

// ---------------------------------------------------
// ------------  Тестовое окружение  -----------------
// ---------------------------------------------------
class Environment
#(
    parameter int TDATA_WIDTH = 128       // размер шины данных
);
    int test_pass = 0;
    int transaction_numb;   // число транзакций

    Generator #(TDATA_WIDTH) gen;
    Driver #(TDATA_WIDTH) dr;
    Monitor #(TDATA_WIDTH) mon;
    Scoreboard #(TDATA_WIDTH) score;

    mailbox mb_driver;
    mailbox mb_scoreboard;
    mailbox mb_monitor;

    virtual AXIS_intf #(TDATA_WIDTH) axis_in;
    virtual AXIS_intf #(TDATA_WIDTH) axis_out;

    // конструктор класса
    function new (int gen_max_delay_ns, int mon_max_delay_ns, int transaction_numb);
        this.transaction_numb = transaction_numb;
        mb_driver = new();
        mb_scoreboard = new();
        mb_monitor = new();
        gen = new(gen_max_delay_ns);
        dr = new();
        mon = new(mon_max_delay_ns);
        score = new();
    endfunction 

    // запуск тестового окружения
    task run();
        automatic int f_result; 
        automatic string file_path = find_file_path(`__FILE__);

        dr.axis = axis_in;
        dr.mb_driver = mb_driver;

        gen.mb_driver = mb_driver;
        gen.mb_scoreboard = mb_scoreboard;

        mon.axis = axis_out;
        mon.mb_monitor = mb_monitor;

        score.mb_monitor = mb_monitor;
        score.mb_driver = mb_scoreboard;

        fork
            gen.run(transaction_numb);
            dr.run(transaction_numb);
            mon.run(transaction_numb);
        join
        
        score.run(transaction_numb); 
        
        test_pass = score.test_pass;
        $finish;
       
    endtask
endclass


