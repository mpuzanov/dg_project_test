CREATE   PROCEDURE [dbo].[ka_show_added]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL
)
AS
	/*
	Выводим разовые по лицевому счету

	exec ka_show_added 910000822, 0
	exec ka_show_added 1004002, 0
	exec ka_show_added 55023431, 254
	
	*/

	SET NOCOUNT ON
	SET LANGUAGE Russian

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current


	IF @fin_id1 >= @fin_current
	BEGIN
		--SELECT
		--	*
		--FROM (
		-- Добавляем разовые по норме
		SELECT ap.Id AS kod
			 , cp.StrFinPeriod AS fin_period
			 , ap.occ
			 , ap.service_id
			 , s.name AS 'services'
			 , ap.Add_type AS Add_type
			 , t.name AS Add_name
			 , ap.doc AS Docum
			 , ap.value AS Summa
			 , CONVERT(CHAR(14), ap.data1, 106) AS data1
			 , CONVERT(CHAR(14), ap.data2, 106) AS data2
			 , ap.doc_no AS doc_no
			 , CONVERT(CHAR(14), ap.doc_date, 106) AS doc_date
			 , SUBSTRING(s1.name, 1, 20) AS Vin1
			 , SUBSTRING(s2.name, 1, 20) AS Vin2
			 , u.Initials AS username
			 , CASE
                   WHEN ap.Hours = 0 THEN NULL
                   ELSE ap.Hours
            END AS Hours
			 , manual_bit
			 , t2.name AS Add_name2
			 , ap.date_edit
			 , ap.comments
			 , YEAR(gb.start_date) AS [year]
			 , ap.tnorm2
			 , ap.kol
			 , CASE
				   WHEN repeat_for_fin IS NULL THEN NULL
				   ELSE dbo.Fun_NameFinPeriod(repeat_for_fin)
			   END AS repeat_for_fin_str
			 , s.service_no
			 , sa.name AS sup_name
			 , ap.Id
			 , '' AS lgotnik_name
		FROM dbo.View_added_lite AS ap 
			JOIN dbo.View_services AS s ON ap.service_id = s.Id
			JOIN dbo.Added_Types AS t ON ap.Add_type = t.Id
			JOIN dbo.Global_values AS gb ON gb.fin_id = @fin_current
			JOIN dbo.Suppliers_all sa ON ap.sup_id = sa.Id
			LEFT OUTER JOIN dbo.Sector AS s1 ON ap.Vin1 = s1.Id
			LEFT OUTER JOIN dbo.View_suppliers AS s2  ON ap.Vin2 = s2.Id
			LEFT OUTER JOIN dbo.Added_Types_2 AS t2 ON ap.add_type2 = t2.Id
			JOIN Calendar_period cp ON cp.fin_id = ap.fin_id
			LEFT JOIN Users AS u ON u.Id = ap.user_edit
		WHERE ap.occ = @occ1
			AND ap.fin_id = @fin_current
		ORDER BY s.service_no

	END

	IF @fin_id1 = 0  -- берём данные из истории
	BEGIN

		SELECT 0 AS kod
			 , gb.StrMes AS fin_period
			 , ap.occ
			 , ap.service_id
			 , s.name AS [services]
			 , ap.Add_type AS Add_type
			 , t.name AS Add_name
			 , ap.doc AS Docum
			 , ap.value AS Summa
			 , CONVERT(VARCHAR(12), data1, 106) AS data1  --'dd MMM yyyy'
			 , CONVERT(VARCHAR(12), data2, 106) AS data2
			 , CONVERT(VARCHAR(12), doc_date, 106) AS doc_date
			 , ap.doc_no
			 , SUBSTRING(s1.name, 1, 20) AS Vin1
			 , SUBSTRING(s2.name, 1, 20) AS Vin2
			 , u.Initials AS username
			 , CASE
                   WHEN ap.Hours = 0 THEN NULL
                   ELSE ap.Hours
            END AS Hours
			 , manual_bit
			 , t2.name AS Add_name2
			 , ap.date_edit AS date_edit
			 , ap.comments
			 , YEAR(gb.start_date) AS [year]
			 , tnorm2
			 , ap.kol
			 , CASE
				   WHEN repeat_for_fin > 0 THEN dbo.Fun_NameFinPeriod(repeat_for_fin)
				   ELSE NULL
			   END AS repeat_for_fin_str
			 , s.service_no
			 , ap.fin_id
			 , sa.name AS sup_name
			 , ap.Id
			 ,'' AS lgotnik_name
		FROM dbo.View_added_lite AS ap 
			JOIN dbo.View_services AS s ON ap.service_id = s.Id
			JOIN dbo.Added_Types AS t ON ap.Add_type = t.Id
			JOIN dbo.Global_values AS gb ON ap.fin_id = gb.fin_id
			JOIN dbo.Suppliers_all sa ON ap.sup_id = sa.Id
			LEFT OUTER JOIN dbo.Sector AS s1 ON ap.Vin1 = s1.Id
			LEFT OUTER JOIN dbo.View_suppliers AS s2 ON ap.Vin2 = s2.Id
			LEFT OUTER JOIN dbo.Added_Types_2 AS t2 ON ap.add_type2 = t2.Id
			LEFT JOIN Users AS u ON u.Id = ap.user_edit
		WHERE ap.occ = @occ1
			AND ap.fin_id < @fin_current
		ORDER BY ap.fin_id DESC
			   , ap.service_id
		OPTION (RECOMPILE)


	END
go

