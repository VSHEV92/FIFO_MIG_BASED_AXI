// ------------------------------------------------------
//---------- настройки тестового окружения  -------------
// ------------------------------------------------------
parameter int CLK_FREQ = 200;               // тактовая частота в MHz  
parameter int RESET_DEASSERT_DELAY = 1000;  // время снятия сигнала сброса ns
parameter int GEN_MAX_DELAY_NS = 100;       // максимальная задержка генератора в нс
parameter int MON_MAX_DELAY_NS = 200;       // максимальная задержка монитора в нс
parameter int SIM_TIMEOUT_NS = 1000_000;    // максимальное время симуляции в нс
parameter int TRANSACTIONS_NUMB = 500;      // количество транзакций