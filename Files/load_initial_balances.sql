CREATE OR REPLACE PROCEDURE "DS"."load_initial_balances"()
as $$
declare
	v_start_time TIMESTAMP;
	v_end_time TIMESTAMP;
	v_duration_sec INTEGER;
	v_rows INTEGER;
	v_error_message TEXT;
	v_process_name VARCHAR(255):= 'load_initial_balances';
	v_date DATE:= '2017-12-31';
BEGIN
	-- Запоминаем время начала
	v_start_time := now();
    
    -- Логируем начало выполнения
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, status, source, user_name)
	values (v_process_name, v_date, v_start_time, 'RUNNING', 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
    
    -- Удаляем данные за указанную дату
	delete from "DM"."DM_ACCOUNT_BALANCE_F" where on_date = v_date;
    
	insert into "DM"."DM_ACCOUNT_BALANCE_F" (on_date, account_rk, balance_out, balance_out_rub)
	SELECT 
        bf.on_date as on_date,
        bf.account_rk as account_rk,
        bf.balance_out as balance_out,
        bf.balance_out * COALESCE(er.reduced_cource, 1) as balance_out_rub
	from "DS"."FT_BALANCE_F" bf
	left join "DS"."MD_ACCOUNT_D" acc on acc.account_rk = bf.account_rk
		and v_date between acc.data_actual_date  and acc.data_actual_end_date
	left join "DS"."MD_EXCHANGE_RATE_D" er ON er.currency_rk = acc.currency_rk
		and v_date between er.data_actual_date and er.data_actual_end_date
	where 1=1
 		and bf.on_date = v_date;
    
	-- Получаем количество вставленных строк
	GET DIAGNOSTICS v_rows = ROW_COUNT;
    
	-- Завершаем логирование
	v_end_time := now();
	v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    
    -- Логируем успешное завершение
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, rows_written, source, user_name)
	values (v_process_name, v_date, v_start_time, v_end_time, v_duration_sec, 'SUCCESS', v_rows, 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
    
	raise notice 'Витрина остатков за % заполнена. Добавлено строк: %', v_date, v_rows;
    
	EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
		v_end_time := CURRENT_TIMESTAMP;
		v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
        
 	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, error_message, rows_error, source, user_name)
	values (v_process_name, v_date, v_start_time, v_end_time, v_duration_sec, 'ERROR', v_error_message, 1, 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
        
	raise notice 'Ошибка при расчёте витрины остатков за %: %', v_date, v_error_message;
END;
$$language plpgsql;