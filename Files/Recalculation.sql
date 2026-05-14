CREATE OR REPLACE PROCEDURE "DS"."Recalculation_Account_Turnover"(start_date date,end_date date)
as $$ 
begin
	while start_date <= end_date LOOP
		call "DS"."fill_account_turnover_f"(start_date);
		start_date := start_date + INTERVAL '1 day';
	end LOOP;
    RAISE NOTICE 'Расчёт витрины оборотов завершён';

EXCEPTION
	WHEN OTHERS THEN
	RAISE NOTICE 'Ошибка при пересчёте витрины оборотов: %', SQLERRM;
END;
$$language plpgsql;


CREATE OR REPLACE PROCEDURE "DS"."Recalculation_Account_Balance"(start_date date,end_date date)
as $$ 
begin
	while start_date <= end_date LOOP
		call "DS"."fill_account_balance_f"(start_date);
		start_date := start_date + INTERVAL '1 day';
	end LOOP;
    RAISE NOTICE 'Расчёт витрины остатков завершён';

EXCEPTION
	WHEN OTHERS THEN
	RAISE NOTICE 'Ошибка при пересчёте витрины остатков: %', SQLERRM;
END;
$$language plpgsql;


