#include "xil_printf.h"
#include "mb_interface.h"

// запись значений счетчика в fifo
// count_init_val - начальное значение счетчика
// words_numb - количество записываемых слов (слово - 128 бит)
void write_to_fifo(int count_init_val, int mem_words_numb);

// чтение и проверка значений счетчика из fifo
// count_init_val - ожидаемое начальное значение счетчика
// words_numb - количество считываемых слов (слово - 128 бит)
bool read_and_check_from_fifo(int count_init_val, int mem_words_numb);

// тестирование записи и чтения
// count_init_val - начальное значение счетчика
// words_numb - количество записываемых слов (слово - 128 бит)
bool rw_test(int count_init_val, int mem_words_numb);

int main(){
	bool test_result = true;

	// запускаем тесты на запись и чтение
	for (int i = 1; i < 45; i++){
		test_result = rw_test(i*i, 2*i);
		if (test_result)
			xil_printf("Test %d Passed! Count_init_val = %d. Mem_words_numb = %d. \r\n", i, i*i, 2*i);
		else
			xil_printf("Test %d Failed! Count_init_val = %d. Mem_words_numb = %d. \r\n", i, i*i, 2*i);
	}

	// вывод результатов тетстирования
	if (test_result){
		xil_printf("--------------------------------\r\n");
		xil_printf("---- VERIFICATION SUCCESSED ----\r\n");
		xil_printf("--------------------------------\r\n");
	} else {
		xil_printf("--------------------------------\r\n");
		xil_printf("------ VERIFICATION FAILED -----\r\n");
		xil_printf("--------------------------------\r\n");
	}

	return 0;
}

// запись значений счетчика в fifo
void write_to_fifo(int count_init_val, int mem_words_numb){
	int counter = count_init_val;
	for (int j = 0; j < mem_words_numb; j++){
		for (int i = 0; i < 4; i++)
			putfsl(counter, 0);
		counter++;
	}
}

// чтение и проверка значений счетчика из fifo
bool read_and_check_from_fifo(int count_init_val, int mem_words_numb){
	int rx_count;
	int gold_count = count_init_val;
	bool check_result = true;

	for (int j = 0; j < mem_words_numb; j++){
		for (int i = 0; i < 4; i++){
			getfsl(rx_count, 0);
			if (gold_count != rx_count)
				check_result = false;
		}
		gold_count++;
	}
	return check_result;
}

// тестирование записи и чтения
bool rw_test(int count_init_val, int mem_words_numb){
	write_to_fifo(count_init_val, mem_words_numb);
	return read_and_check_from_fifo(count_init_val, mem_words_numb);
}
