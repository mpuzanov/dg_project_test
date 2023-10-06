-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE      PROCEDURE [dbo].[rep_favorites_click_generate]
/*
exec rep_favorites_click_generate
*/
AS
BEGIN

SET NOCOUNT ON;

	DECLARE @name VARCHAR(100)
		,@sql_query VARCHAR(8000)
		,@user_id INT = dbo.Fun_GetCurrentUserId()

SELECT
	@name = 'Список баз'
   ,@sql_query = 'show databases'

IF NOT EXISTS (SELECT
			*
		FROM dbo.Reports_favorites
		WHERE [name] = @name)
INSERT INTO dbo.Reports_favorites (user_id, is_for_all, rep_type, [name], sql_query)
	VALUES (@user_id, 1, 'CLICKHOUSE', @name, @sql_query)

SELECT
	@name = 'Начисления по домам'
   ,@sql_query = '
-- Начисления по домам
SELECT 
  start_date AS `Период`
,  tip_name AS `Тип фонда`
,  street_name AS `Улица`
,  nom_dom AS `Номер дома`
,  SUM( saldo) AS `Вх_сальдо`
,  SUM( SaldoWithPeny) AS `Вх_сальдо с пени`
,  SUM( value) AS `Начислено`
,  SUM( added) AS `Разовые`
,  SUM( paid) AS `Пост_Начисление`
,  SUM( PaidWithPeny) AS `Пост_Начисление с пени`
,  SUM( PaymAccount) AS `Оплата`
,  SUM( PaymAccount_peny) AS `Оплата пени`
,  SUM( PaymAccount_serv) AS `Оплата по услуге`
,  SUM( Debt) AS `Кон_Сальдо`
,  SUM( DebtWithPeny) AS `Кон_Сальдо с пени`
,  SUM( kol) AS `Кол-во`
,  SUM( kol_added) AS `Кол-во разовых`
,  SUM( penalty_old) AS `Пени стар`
,  SUM( penalty_serv) AS `Пени`
,  SUM( penalty_itog) AS `Пени итого`
FROM ds_paym
<WHERE></WHERE>
GROUP BY start_date,tip_name,street_name,nom_dom,nom_dom_sort
ORDER BY `start_date` DESC,`street_name` ASC,`nom_dom_sort` ASC
LIMIT 10000
   '

IF NOT EXISTS (SELECT
			*
		FROM dbo.Reports_favorites
		WHERE [name] = @name)
INSERT INTO dbo.Reports_favorites (user_id, is_for_all, rep_type, [name], sql_query)
	VALUES (@user_id, 1, 'CLICKHOUSE', @name, @sql_query)

--=================================================================
SELECT
	@name = 'Начисления по домам по услугам'
   ,@sql_query = '
-- Начисления по домам по услугам
SELECT 
  start_date AS `Период`
,  tip_name AS `Тип фонда`
,  street_name AS `Улица`
,  nom_dom AS `Номер дома`
,  serv_name AS `Услуга`
,  SUM( saldo) AS `Вх_сальдо`
,  SUM( SaldoWithPeny) AS `Вх_сальдо с пени`
,  SUM( value) AS `Начислено`
,  SUM( added) AS `Разовые`
,  SUM( paid) AS `Пост_Начисление`
,  SUM( PaidWithPeny) AS `Пост_Начисление с пени`
,  SUM( PaymAccount) AS `Оплата`
,  SUM( PaymAccount_peny) AS `Оплата пени`
,  SUM( PaymAccount_serv) AS `Оплата по услуге`
,  SUM( Debt) AS `Кон_Сальдо`
,  SUM( DebtWithPeny) AS `Кон_Сальдо с пени`
,  SUM( kol) AS `Кол-во`
,  SUM( kol_added) AS `Кол-во разовых`
,  SUM( penalty_old) AS `Пени стар`
,  SUM( penalty_serv) AS `Пени`
,  SUM( penalty_itog) AS `Пени итого`
FROM ds_paym
<WHERE></WHERE>
GROUP BY start_date, tip_name, street_name, nom_dom, nom_dom_sort, serv_name
ORDER BY `start_date` DESC,`street_name` ASC,`nom_dom_sort` ASC, serv_name
LIMIT 100000   
   '
IF NOT EXISTS (SELECT
			*
		FROM dbo.Reports_favorites
		WHERE [name] = @name)
INSERT INTO dbo.Reports_favorites (user_id, is_for_all, rep_type, [name], sql_query)
	VALUES (@user_id, 1, 'CLICKHOUSE', @name, @sql_query)


SELECT
	@name = 'Процент оплаты по домам'
   ,@sql_query = '
-- Процент оплаты по домам
SELECT 
start_date AS `Период`
,street_name AS `Улица`
,nom_dom AS `Номер дома`
,SUM(saldo) AS `Начальное_сальдо`
,SUM(PaidWithPeny) AS `Пост_Начисление с пени`
,SUM(PaymAccount) AS `Оплата`
,IF(SUM(PaidWithPeny)=0,0,ROUND(SUM(PaymAccount)*100/SUM(PaidWithPeny),2)) AS `Процент`
FROM ds_paym
<WHERE></WHERE>
GROUP BY street_name,nom_dom,nom_dom_sort,start_date
ORDER BY `street_name` ASC,`nom_dom_sort` ASC
LIMIT 10000
   '

IF NOT EXISTS (SELECT
			*
		FROM dbo.Reports_favorites
		WHERE [name] = @name)
INSERT INTO dbo.Reports_favorites (user_id, is_for_all, rep_type, [name], sql_query)
	VALUES (@user_id, 1, 'CLICKHOUSE', @name, @sql_query)


END
go

