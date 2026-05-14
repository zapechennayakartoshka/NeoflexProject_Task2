CREATE OR REPLACE PROCEDURE "DS"."fill_account_balance_f"(i_OnDate date)
as $$
declare
	v_start_time TIMESTAMP;
	v_end_time TIMESTAMP;
	v_duration_sec INTEGER;
	v_rows INTEGER;
	v_error_message TEXT;
	v_process_name VARCHAR(255):= 'fill_account_balance_f'; 
	v_prev_date DATE;
BEGIN
	-- Запоминаем время начала
	v_start_time := now();
    
    -- Логируем начало выполнения
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, status, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, 'RUNNING', 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
    
    -- Удаляем данные за указанную дату
	delete from "DM"."DM_ACCOUNT_BALANCE_F" where on_date = i_OnDate;
    
	v_prev_date := i_OnDate - INTERVAL '1 day';

	insert into "DM"."DM_ACCOUNT_BALANCE_F" (on_date, account_rk, balance_out, balance_out_rub)
	SELECT 
        i_OnDate as on_date,
        acc.account_rk as account_rk,
		case 
			when acc.char_type = 'А' then COALESCE(prev.balance_out, 0) + COALESCE(turn.debet_amount, 0) - COALESCE(turn.credit_amount, 0)
			when acc.char_type = 'П' then COALESCE(prev.balance_out, 0) - COALESCE(turn.debet_amount, 0) + COALESCE(turn.credit_amount, 0)
            else COALESCE(prev.balance_out, 0)
        end as balance_out,
		case 
			when acc.char_type = 'А' then COALESCE(prev.balance_out_rub, 0) + COALESCE(turn.debet_amount_rub, 0) - COALESCE(turn.credit_amount_rub, 0)
			when acc.char_type = 'П' then COALESCE(prev.balance_out_rub, 0) - COALESCE(turn.debet_amount_rub, 0) + COALESCE(turn.credit_amount_rub, 0)
            else COALESCE(prev.balance_out_rub, 0)
        end as balance_out_rub
	FROM "DS"."MD_ACCOUNT_D" acc 
	left join "DM"."DM_ACCOUNT_BALANCE_F" prev on prev.account_rk = acc.account_rk and prev.on_date = v_prev_date
	left join "DM"."DM_ACCOUNT_TURNOVER_F" turn on turn.account_rk = acc.account_rk and turn.on_date = i_OnDate
	where 1=1
 	and i_OnDate between acc.data_actual_date and acc.data_actual_end_date;
    
	-- Получаем количество вставленных строк
	GET DIAGNOSTICS v_rows = ROW_COUNT;
    
	-- Завершаем логирование
	v_end_time := now();
	v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    
    -- Логируем успешное завершение
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, rows_written, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, v_end_time, v_duration_sec, 'SUCCESS', v_rows, 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
    
	raise notice 'Витрина остатков за % заполнена. Добавлено строк: %', i_OnDate, v_rows;
    
	EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
		v_end_time := CURRENT_TIMESTAMP;
		v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
        
 	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, error_message, rows_error, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, v_end_time, v_duration_sec, 'ERROR', v_error_message, 1, 'DM.DM_ACCOUNT_BALANCE_F', CURRENT_USER);
        
	raise notice 'Ошибка при расчёте витрины остатков за %: %', i_OnDate, v_error_message;
END;
$$language plpgsql;