CREATE SCHEMA "DM"

CREATE TABLE "DM"."DM_ACCOUNT_TURNOVER_F" (
	on_date DATE not null,
	account_rk BIGINT not null,
	credit_amount NUMERIC(23,8),
	credit_amount_rub NUMERIC(23,8),
	debet_amount NUMERIC(23,8),
	debet_amount_rub NUMERIC(23,8),

	CONSTRAINT pk_dm_turnover PRIMARY KEY (on_date, account_rk)
);

CREATE TABLE "DM"."DM_ACCOUNT_BALANCE_F" (
	on_date DATE not null,
	account_rk BIGINT not null,
	balance_out NUMERIC(23,8),
	balance_out_rub NUMERIC(23,8),
	    
	CONSTRAINT pk_dm_balance PRIMARY KEY (on_date, account_rk)
);

TRUNCATE table "DM"."DM_ACCOUNT_BALANCE_F";
TRUNCATE table "DM"."DM_ACCOUNT_TURNOVER_F";

CALL "DS"."load_initial_balances"();


select * from "DM"."DM_ACCOUNT_BALANCE_F";
SELECT * FROM "LOGS"."ETL_LOG" ORDER BY log_id DESC;

CALL "DS"."Recalculation_Account_Turnover"('2018-01-01', '2018-01-31');

select * from "DM"."DM_ACCOUNT_TURNOVER_F";
SELECT * FROM "LOGS"."ETL_LOG" ORDER BY log_id DESC;

call "DS"."Recalculation_Account_Balance"('2018-01-01', '2018-01-31');

select * from "DM"."DM_ACCOUNT_BALANCE_F";
SELECT * FROM "LOGS"."ETL_LOG" ORDER BY log_id DESC;

select * from "DM"."DM_ACCOUNT_TURNOVER_F"
select * from "DS"."MD_ACCOUNT_D"
 
select * from "DS"."MD_ACCOUNT_D"where account_rk=13631
select * from "DS"."MD_EXCHANGE_RATE_D" where  currency_rk=34;
select * from "DM"."DM_ACCOUNT_TURNOVER_F"
where account_rk=13630
and on_date='2018-01-18'

select sum(credit_amount) from "DS"."FT_POSTING_F" po
		where po.oper_date = '2018-01-18'
		and credit_account_rk=13630

select 
			po.credit_account_rk as account_rk,
			po.credit_amount as credit_amount, 
			po.oper_date
        from "DS"."FT_POSTING_F" po
		where po.oper_date = '2018-01-09'
		and credit_account_rk=13631
		order by credit_amount
		group by po.credit_account_rk
		
SELECT acc.account_rk, acc.currency_rk, er.reduced_cource, er.data_actual_date
FROM "DS"."MD_ACCOUNT_D" acc
LEFT JOIN "DS"."MD_EXCHANGE_RATE_D" er ON er.currency_rk = acc.currency_rk
   -- AND '2018-01-09' BETWEEN er.data_actual_date AND COALESCE(er.data_actual_end_date, '9999-12-31')
WHERE acc.account_rk = 13631
order by data_actual_date;	

select 
    currency_rk,
    count(*)
from "DS"."MD_EXCHANGE_RATE_D"
where data_actual_date <= '2018-01-31' and account_rk = 13631;	
group by currency_rk
having count(*) > 1;

SELECT 
    *
FROM "DS"."MD_ACCOUNT_D" acc
LEFT JOIN "DS"."MD_CURRENCY_D" cur ON cur.currency_rk = acc.currency_rk
WHERE acc.account_rk = 13631;

select * from "DS"."MD_CURRENCY_D"
 select * from "DM"."DM_ACCOUNT_BALANCE_F" where balance_out<>balance_out_rub;


SELECT * FROM "DM"."DM_ACCOUNT_TURNOVER_F" 
WHERE account_rk = 13631 
ORDER BY on_date;

SELECT * FROM "DM"."DM_ACCOUNT_BALANCE_F" 
WHERE account_rk = 13631 
ORDER BY on_date;


--ПРОВЕРКА

-- Проводки по кредиту счета 13631 за 10.01.2018
SELECT oper_date, credit_account_rk, credit_amount
FROM "DS"."FT_POSTING_F" 
WHERE credit_account_rk = 13631 AND oper_date = '2018-01-10';

-- Проводки по дебету счета 13631 за 10.01.2018
SELECT oper_date, debet_account_rk, debet_amount
FROM "DS"."FT_POSTING_F" 
WHERE debet_account_rk = 13631 AND oper_date = '2018-01-10';

--СУММА ПО КРЕДТУ И ДЕБИТУ

-- Кредитовый оборот  --537071.23
SELECT 
    'CREDIT' AS type,
    SUM(credit_amount) AS total_amount
FROM "DS"."FT_POSTING_F" 
WHERE credit_account_rk = 13631 AND oper_date = '2018-01-10'

UNION all 

-- Дебетовый оборот  --472145.23
SELECT 
    'DEBET' AS type,
    SUM(debet_amount) AS total_amount
FROM "DS"."FT_POSTING_F" 
WHERE debet_account_rk = 13631 AND oper_date = '2018-01-10';

--ОПРЕДЕЛЯЕМ ВАЛЮТУ СЧЕТА 35

SELECT  account_rk, currency_rk, char_type
FROM "DS"."MD_ACCOUNT_D" 
WHERE account_rk = 13631 

--НАХОДИМ КУРС ВАЛЮТЫ --57.0463

SELECT  currency_rk, reduced_cource, data_actual_date
FROM "DS"."MD_EXCHANGE_RATE_D" er
WHERE er.currency_rk = 35  AND er.data_actual_date = '2018-01-10'
    
 --РАСЧЕТ
    
    SELECT 
    'РУЧНОЙ',
    '2018-01-10',
    13631 ,
    537071.23 AS credit_amount,
    537071.23 * 57.0463 AS credit_amount_rub_calculated,
    472145.23 AS debet_amount,
    472145.23 * 57.0463 AS debet_amount_rub_calculated
    
    union all
    
    SELECT 
    'DM_ACCOUNT_TURNOVER_F',
    on_date,
    account_rk,
    credit_amount,
    credit_amount_rub,
    debet_amount,
    debet_amount_rub
FROM "DM"."DM_ACCOUNT_TURNOVER_F" 
WHERE account_rk = 13631 AND on_date = '2018-01-10';


--ВТОРАЯ ПРОВЕРКА

select * from "DM"."DM_ACCOUNT_BALANCE_F" where account_rk= 13631 AND on_date = '2018-01-10';


--НАХОДИМ ЗА ПРЕДЫДУЩИЙ ДЕНЬ balance_out=453284.74000000 balance_out_rub=19623478.15896000

select * from "DM"."DM_ACCOUNT_BALANCE_F" where account_rk= 13631 AND on_date = '2018-01-09';

--СЧЕТ АКТИВНЫЙ

SELECT  
    on_date, account_rk, redit_amount, credit_amount_rub, debet_amount,  debet_amount_rub
FROM "DM"."DM_ACCOUNT_TURNOVER_F" 
WHERE account_rk = 13631 AND on_date = '2018-01-10';


--when acc.char_type = 'А' then COALESCE(prev.balance_out, 0) + COALESCE(turn.debet_amount, 0) - COALESCE(turn.credit_amount, 0)

--when acc.char_type = 'А' then COALESCE(prev.balance_out_rub, 0) + COALESCE(turn.debet_amount_rub, 0) - COALESCE(turn.credit_amount_rub, 0)

SELECT 
    453284.74 AS prev_balance_out,
    472145.23 AS debet_amount,
	537071.23 AS credit_amount,
	453284.74 + 472145.23 - 537071.23 AS calculated_balance_out,
    19623478.15896 AS prev_balance_out_rub,
    26934138.434149 AS debet_amount_rub,
    30637926.507949 AS credit_amount_rub,
    19623478.15896 + 26934138.434149 - 30637926.507949 AS calculated_balance_out_rub;

select * from "DM"."DM_ACCOUNT_BALANCE_F" where account_rk= 13631 AND on_date = '2018-01-10';
