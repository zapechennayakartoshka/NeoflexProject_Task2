CREATE OR REPLACE PROCEDURE "DS"."fill_account_turnover_f"(i_OnDate date)
as $$
declare
	v_start_time TIMESTAMP;
	v_end_time TIMESTAMP;
	v_duration_sec INTEGER;
	v_rows INTEGER;
	v_error_message TEXT;
	v_process_name VARCHAR(255) := 'fill_account_turnover_f';
BEGIN
	-- Запоминаем время начала
	v_start_time := now();
    
    -- Логируем начало выполнения
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, status, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, 'RUNNING', 'DM.DM_ACCOUNT_TURNOVER_F', CURRENT_USER);
    
    -- Удаляем данные за указанную дату
	delete from "DM"."DM_ACCOUNT_TURNOVER_F" where on_date = i_OnDate;
    
	with  
	credit_amount_cte as ( --для расчета credit_amount
		select 
			po.credit_account_rk as account_rk,
			sum(po.credit_amount) as credit_amount
        from "DS"."FT_POSTING_F" po
		where po.oper_date = i_OnDate
		group by po.credit_account_rk),

	debet_amount_cte as ( --для расчета debet_amount
		select 
			po.debet_account_rk as account_rk,
			sum(po.debet_amount) as debet_amount
        from "DS"."FT_POSTING_F" po
		where po.oper_date = i_OnDate
		group by po.debet_account_rk),

	all_accounts as ( --все account
		select account_rk from credit_amount_cte
		union
		select account_rk from debet_amount_cte
    )

	INSERT INTO "DM"."DM_ACCOUNT_TURNOVER_F" (on_date, account_rk, credit_amount, credit_amount_rub, debet_amount, debet_amount_rub)
	SELECT 
		i_OnDate as on_date,
		al.account_rk as account_rk,
		COALESCE(c.credit_amount, 0) as credit_amount,
		COALESCE(c.credit_amount, 0) * COALESCE(er.reduced_cource, 1) as credit_amount_rub,
		COALESCE(d.debet_amount, 0) as debet_amount,
		COALESCE(d.debet_amount, 0) * COALESCE(er.reduced_cource, 1) as debet_amount_rub
    from all_accounts al
	left join credit_amount_cte c on c.account_rk = al.account_rk
	left join debet_amount_cte d on d.account_rk = al.account_rk
	left join "DS"."MD_ACCOUNT_D" acc on acc.account_rk = al.account_rk
		and i_OnDate between acc.data_actual_date and acc.data_actual_end_date
	left join (
    select currency_rk, reduced_cource,data_actual_end_date,data_actual_date
	from (
		select 
			er.*,
            row_number() over (partition by currency_rk order by data_actual_date desc) as rn
        from "DS"."MD_EXCHANGE_RATE_D" er
        where data_actual_date <= i_OnDate
    ) t
    where rn = 1
	) er 
on er.currency_rk = acc.currency_rk
 ;
    
	-- Получаем количество вставленных строк
	GET DIAGNOSTICS v_rows = ROW_COUNT;
    
	-- Завершаем логирование
	v_end_time := now();
	v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    
    -- Логируем успешное завершение
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, rows_written, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, v_end_time, v_duration_sec, 'SUCCESS', v_rows, 'DM.DM_ACCOUNT_TURNOVER_F', CURRENT_USER);
    
	raise notice 'Витрина оборотов за % заполнена. Добавлено строк: %', i_OnDate, v_rows;
    
	EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
		v_end_time := CURRENT_TIMESTAMP;
		v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
        
 	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, error_message, rows_error, source, user_name)
	values (v_process_name, i_OnDate, v_start_time, v_end_time, v_duration_sec, 'ERROR', v_error_message, 1, 'DM.DM_ACCOUNT_TURNOVER_F', CURRENT_USER);
        
	raise notice 'Ошибка при расчёте витрины оборотов за %: %', i_OnDate, v_error_message;
END;
$$language plpgsql;