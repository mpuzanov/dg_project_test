-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE      PROCEDURE [dbo].[rep_olap_history]
	  @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @number_query SMALLINT = 1
AS
/*
1 - по услугам по домам за период
2 - по услугам по домам списком
3 - по услугам по лицевым за период
4 - по услугам по лицевым списоком

exec rep_olap_history @tip_id=131  -- kr1
exec rep_olap_history @tip_id=131, @number_query=2  -- kr1
exec rep_olap_history @tip_id=131, @fin_id1=245, @fin_id2=250
exec rep_olap_history @tip_id=131, @fin_id1=245, @fin_id2=250, @sup_id=345, @number_query=2
exec rep_olap_history @tip_id=1, @fin_id1=245, @fin_id2=250, @build_id=6786

exec rep_olap_history @tip_id=3, @fin_id1=245, @fin_id2=250 -- komp, naim
exec rep_olap_history @tip_id=137, @fin_id1=245, @fin_id2=250, @build_id=4820 -- komp_spdu
exec rep_olap_history @tip_id=27, @fin_id1=245, @fin_id2=250, @build_id=520  -- kvart
*/
BEGIN
	SET NOCOUNT ON;

	SET @number_query=coalesce(@number_query,1)

	DECLARE @db_name VARCHAR(15) = DB_NAME()
	DECLARE @tip VARCHAR(10) = LTRIM(STR(@tip_id))
	DECLARE @str VARCHAR(MAX)
	
	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current-1

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @number_query=1
	BEGIN -- 1 - по услугам по домам за период
		SET @str = ''
		;WITH cte AS (
		SELECT
			b.tip_name AS 'Тип фонда'
			,b.adres AS 'Адрес дома'
			,s.name as 'Услуга'
			,SUM(CASE WHEN(ph.fin_id=@fin_id1) THEN ph.saldo ELSE 0 END) as 'Нач. сальдо'

			,SUM(ph.value) as 'Начислено'
			,SUM(ph.added) as 'Разовые'
			,SUM(ph.paid) as 'Пост.начисл.'
			,SUM(ph.paymaccount) as 'Оплачено'
			,SUM(ph.paymaccount_peny) as 'из них пени'
			,SUM(ph.paymaccount - ph.paymaccount_peny) as 'Оплачено по услугам'
		
			,SUM(CASE WHEN(ph.fin_id=@fin_id2) THEN ph.debt ELSE 0 END) as 'Кон. сальдо'
			,SUM(CASE WHEN(ph.fin_id=@fin_id1) THEN ph.penalty_prev ELSE 0 END) as 'Пени старое'

			,SUM(ph.penalty_serv) as 'Пени тек'
		
			,SUM(CASE WHEN(ph.fin_id=@fin_id2) THEN ph.penalty_prev - ph.paymaccount_peny + ph.penalty_serv ELSE 0 END) as 'Пени итог'
		
			,SUM(ph.kol) as 'Объём услуги'
			,SUM(ph.kol_added) as 'Объём разовых'
		FROM dbo.Paym_history as ph 
			JOIN dbo.Occ_history as oh ON 
				ph.fin_id=oh.fin_id 
				AND ph.occ=oh.occ
			JOIN dbo.Flats as f ON 
				oh.flat_id=f.id
			JOIN dbo.View_buildings as b ON 
				f.bldn_id=b.id
			JOIN dbo.Calendar_period as cp ON 
				oh.fin_id=cp.fin_id
			JOIN dbo.Services as s ON 
				s.id=ph.service_id
		WHERE 
			ph.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (oh.tip_id=@tip_id OR @tip_id is NULL)
			AND (f.bldn_id=@build_id OR @build_id is NULL)
			AND (ph.sup_id=@sup_id OR @sup_id is NULL)
		GROUP BY b.tip_name, b.adres, s.name
		)
		SELECT *
		FROM cte
		ORDER BY 'Тип фонда', 'Адрес дома', 'Услуга'
	END
	IF @number_query=2
	BEGIN --2 - по услугам по домам списком
		SET @str = ''
		;WITH cte AS (
		SELECT
			 cp.start_date AS 'Период'
			,b.tip_name AS 'Тип фонда'
			,b.adres AS 'Адрес дома'
			,s.name as 'Услуга'
			,SUM(ph.saldo) as 'Нач. сальдо'
			,SUM(ph.value) as 'Начислено'
			,SUM(ph.added) as 'Разовые'
			,SUM(ph.paid) as 'Пост.начисл.'
			,SUM(ph.paymaccount) as 'Оплачено'
			,SUM(ph.paymaccount_peny) as 'из них пени'
			,SUM(ph.paymaccount - ph.paymaccount_peny) as 'Оплачено по услугам'
			,SUM(ph.debt) as 'Кон. сальдо'
			,SUM(ph.penalty_prev) as 'Пени старое'
			,SUM(ph.penalty_serv) as 'Пени тек'
			,SUM(ph.penalty_prev - ph.paymaccount_peny + ph.penalty_serv) as 'Пени итог'
			,SUM(ph.kol) as 'Объём услуги'
			,SUM(ph.kol_added) as 'Объём разовых'
		FROM dbo.Paym_history as ph  
			JOIN dbo.Occ_history as oh ON 
				ph.fin_id=oh.fin_id 
				AND ph.occ=oh.occ
			JOIN dbo.Flats as f ON 
				oh.flat_id=f.id
			JOIN dbo.View_buildings as b ON 
				f.bldn_id=b.id
			JOIN dbo.Calendar_period as cp ON 
				oh.fin_id=cp.fin_id
			JOIN dbo.Services as s ON 
				s.id=ph.service_id
		WHERE 
			ph.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (oh.tip_id=@tip_id OR @tip_id is NULL)
			AND (f.bldn_id=@build_id OR @build_id is NULL)
			AND (ph.sup_id=@sup_id OR @sup_id is NULL)
		GROUP BY cp.start_date, b.tip_name, b.adres, s.name
		)
		SELECT *
		FROM cte
		ORDER BY 'Период', 'Тип фонда', 'Адрес дома'	
	END
	IF @number_query=3
	BEGIN --3 - по услугам по лицевым за период
		;WITH cte AS (
		SELECT
			b.tip_name AS 'Тип фонда'
			,b.adres AS 'Адрес дома'
			,f.nom_kvr as '№ помещения'
			,ph.occ as 'Лицевой'
			,s.name as 'Услуга'
			,SUM(CASE WHEN(ph.fin_id=@fin_id1) THEN ph.saldo ELSE 0 END) as 'Нач. сальдо'
			,SUM(ph.value) as 'Начислено'
			,SUM(ph.added) as 'Разовые'
			,SUM(ph.paid) as 'Пост.начисл.'
			,SUM(ph.paymaccount) as 'Оплачено'
			,SUM(ph.paymaccount_peny) as 'из них пени'
			,SUM(ph.paymaccount - ph.paymaccount_peny) as 'Оплачено по услугам'

			,SUM(CASE WHEN(ph.fin_id=@fin_id2) THEN ph.debt ELSE 0 END) as 'Кон. сальдо'
			,SUM(CASE WHEN(ph.fin_id=@fin_id1) THEN ph.penalty_prev ELSE 0 END) as 'Пени старое'
		
			,SUM(ph.penalty_serv) as 'Пени тек'
		
			,SUM(CASE WHEN(ph.fin_id=@fin_id2) THEN ph.penalty_prev - ph.paymaccount_peny + ph.penalty_serv ELSE 0 END) as 'Пени итог'

			,SUM(ph.kol) as 'Объём услуги'
			,SUM(ph.kol_added) as 'Объём разовых'
			,MAX(f.nom_kvr_sort) AS nom_kvr_sort
		FROM dbo.Paym_history as ph  
			JOIN dbo.Occ_history as oh ON 
				ph.fin_id=oh.fin_id 
				AND ph.occ=oh.occ
			JOIN dbo.Flats as f ON 
				oh.flat_id=f.id
			JOIN dbo.View_buildings as b ON 
				f.bldn_id=b.id
			JOIN dbo.Services as s ON 
				s.id=ph.service_id
		WHERE 
			ph.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (@tip_id is NULL OR oh.tip_id=@tip_id)
			AND (@build_id is NULL OR f.bldn_id=@build_id)
			AND (@sup_id is NULL OR ph.sup_id=@sup_id)
		GROUP BY b.tip_name, b.adres, f.nom_kvr, ph.occ, s.name
		)
		SELECT *
		FROM cte
		ORDER BY 'Тип фонда', 'Адрес дома', nom_kvr_sort
	END
	IF @number_query=4
	BEGIN -- 4 - по услугам по лицевым списоком
		;WITH cte AS (
		SELECT
			cp.start_date AS 'Период'
			,b.tip_name AS 'Тип фонда'
			,b.adres AS 'Адрес дома'
			,f.nom_kvr as '№ помещения'
			,ph.occ as 'Лицевой'
			,MAX(oh.total_sq) as 'Площадь'
			,s.name as 'Услуга'
			,SUM(ph.saldo) as 'Нач. сальдо'
			,SUM(ph.value) as 'Начислено'
			,SUM(ph.added) as 'Разовые'
			,SUM(ph.paid) as 'Пост.начисл.'
			,SUM(ph.paymaccount) as 'Оплачено'
			,SUM(ph.paymaccount_peny) as 'из них пени'
			,SUM(ph.paymaccount - ph.paymaccount_peny) as 'Оплачено по услугам'
			,SUM(ph.debt) as 'Кон. сальдо'
			,SUM(ph.penalty_prev) as 'Пени старое'
			,SUM(ph.penalty_serv) as 'Пени тек'
			,SUM(ph.penalty_prev - ph.paymaccount_peny + ph.penalty_serv) as 'Пени итог'
			,SUM(ph.kol) as 'Объём услуги'
			,SUM(ph.kol_added) as 'Объём разовых'
			,MAX(f.nom_kvr_sort) AS nom_kvr_sort
		FROM dbo.Paym_history as ph  
			JOIN dbo.Occ_history as oh ON 
				ph.fin_id=oh.fin_id 
				AND ph.occ=oh.occ
			JOIN dbo.Calendar_period as cp ON 
				oh.fin_id=cp.fin_id
			JOIN dbo.Flats as f ON 
				oh.flat_id=f.id
			JOIN dbo.View_buildings as b ON 
				f.bldn_id=b.id			
			JOIN dbo.Services as s ON 
				s.id=ph.service_id
		WHERE 
			ph.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (@tip_id is NULL OR oh.tip_id=@tip_id)
			AND (@build_id is NULL OR f.bldn_id=@build_id)
			AND (@sup_id is NULL OR ph.sup_id=@sup_id)
		GROUP BY cp.start_date, b.tip_name, b.adres, f.nom_kvr, ph.occ, s.name
		)
		SELECT *
		FROM cte
		ORDER BY 'Период', 'Тип фонда', 'Адрес дома', nom_kvr_sort
	END

END
go

