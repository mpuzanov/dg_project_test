-- =============================================
-- Author:		Пузанов
-- Create date: 22.04.2011
-- Description:	по договорам
-- =============================================
CREATE               PROCEDURE [dbo].[rep_olap_dogovor]
(
	@build	 INT	  = NULL
   ,@fin_id1 SMALLINT = NULL
   ,@fin_id2 SMALLINT = NULL
   ,@tip_id	 SMALLINT = NULL
   ,@sup_id	 INT	  = NULL
)
AS
/*
По договорам
rep_olap_dogovor NULL,147,147,28,323
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	-- для ограничения доступа услуг
	CREATE TABLE #s
	(
		id	 VARCHAR(10) COLLATE database_default PRIMARY KEY
	   ,[name] VARCHAR(100) COLLATE database_default
	)
	INSERT
	INTO #s
	(id
	,name)
		SELECT
			id
		   ,name
		FROM dbo.View_SERVICES


	SELECT
		t.Договор AS 'Договор'
	   ,t.name_str1 AS 'Получатель'
	   ,t.BANK AS 'Банк'
	   ,t.rasschet AS 'Расчётный счёт'
	   ,t.Период AS 'Период'
	   ,t.Поставщик AS 'Поставщик'
	   ,t.НаселенныйПункт
	   ,t.[Адрес дома] AS 'Адрес дома'
	   ,t.Улица AS 'Улица'
	   ,t.nom_dom AS 'Номер дома'
	   ,t.Квартира AS 'Квартира'
	   ,p.occ AS 'Лицевой'
	   ,s.name AS 'Услуга'
	   ,p.tarif AS 'Тариф'
	   ,SUM(p.saldo - p.Paymaccount_serv) AS 'Задолженность'
	   ,SUM(p.saldo) AS 'Сальдо'
	   ,SUM(p.value) AS 'Начислено'
	   ,SUM(p.added) AS 'Разовые'
	   ,SUM(p.paid) AS 'Пост_Начисление'
	   ,SUM(p.paymaccount) AS 'Оплачено'
	   ,SUM(p.paymaccount_peny) AS 'из_них_пени'
	   ,SUM(COALESCE(p.Paymaccount_serv, 0)) AS 'Оплата_без_пени'
	   ,SUM(p.debt) AS 'Кон_Сальдо'
	   ,SUM(p.kol) AS 'Количество'
	   ,SUM(COALESCE(p.penalty_old, 0)) AS 'Пени старое'
	   ,SUM(COALESCE(p.penalty_serv, 0)) AS 'Пени новое'
	   ,SUM(COALESCE(p.penalty_old, 0) + COALESCE(p.penalty_serv, 0)) AS 'Пени итог'
	   ,t.build_id AS 'Код дома'
	   ,t.nom_kvr_sort
	   ,t.nom_dom_sort
	   ,CONCAT(t.Улица, t.nom_dom_sort) AS sort_dom
	FROM (SELECT
			dog.dog_name AS Договор
		   ,gb.start_date AS Период
		   ,sup.name AS Поставщик
		   ,T.name AS НаселенныйПункт
		   ,st.name AS Улица
		   ,b.nom_dom AS nom_dom
		   ,f.nom_kvr AS Квартира
		   ,f.nom_kvr_sort
		   ,CONCAT(st.name , ' д.' , b.nom_dom) AS 'Адрес дома'
		   ,b.nom_dom_sort
		   ,o.occ
		   ,dog.sup_id
		   ,service_id
		   ,dog.fin_id
		   ,b.id AS build_id
		   ,ao.name_str1
		   ,ao.BANK
		   ,ao.rasschet
		FROM [dbo].[View_DOG_ALL] AS dog 
		JOIN dbo.BUILDINGS AS b 
			ON dog.build_id = b.id
		JOIN dbo.FLATS AS f
			ON b.id = f.bldn_id
		JOIN dbo.OCCUPATIONS AS o 
			ON f.id = o.flat_id
		JOIN dbo.VSTREETS AS st 
			ON b.street_id = st.id
		JOIN dbo.GLOBAL_VALUES AS gb 
			ON dog.fin_id = gb.fin_id
		JOIN dbo.SUPPLIERS_ALL AS sup 
			ON dog.sup_id = sup.id
		JOIN dbo.TOWNS AS T 
			ON b.town_id = T.id
		LEFT JOIN dbo.ACCOUNT_ORG AS ao
			ON dog.bank_account = ao.id
		WHERE dog.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@tip_id IS NULL OR dog.tip_id = @tip_id)
		AND (@sup_id IS NULL OR dog.sup_id = @sup_id)
		AND (@build IS NULL OR dog.build_id = @build)) AS t
	JOIN dbo.View_PAYM AS p
		ON t.fin_id = p.fin_id
		AND t.service_id = p.service_id
		AND t.sup_id = p.sup_id
		AND t.occ = p.occ
	JOIN #s AS s
		ON p.service_id = s.id
	WHERE 
		p.fin_id BETWEEN @fin_id1 AND @fin_id2
	GROUP BY t.Договор
			,t.name_str1
			,t.BANK
			,t.rasschet
			,t.Период
			,t.Поставщик
			,t.НаселенныйПункт
			,t.[Адрес дома]
			,t.build_id
			,t.nom_dom_sort
			,t.Улица
			,t.nom_dom
			,t.Квартира
			,t.nom_kvr_sort
			,p.occ
			,s.name
			,p.tarif
	OPTION (RECOMPILE, MAXDOP 1);


END
go

