CREATE   PROCEDURE [dbo].[rep_counter_exp_sber]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT -- код типа фонда
	, @serv_str VARCHAR(2000) = NULL -- список кодов услуг через ","
	, @build_id1 INT = NULL
	, @date1 SMALLDATETIME = NULL
	, @date2 SMALLDATETIME = NULL
	, @debug BIT = 0
)
AS
/*
exec rep_counter_exp_sber @fin_id1=250, @tip_id1=2, @debug=0
*/
BEGIN
	SET NOCOUNT ON;


	DECLARE @tip TABLE (
		  tip_id INT PRIMARY KEY
		, fin_id SMALLINT DEFAULT NULL
		, inn VARCHAR(10)
		, bank_account INT DEFAULT NULL
		, tip_name VARCHAR(50) DEFAULT NULL
	)

	INSERT INTO @tip
		(tip_id
	   , inn
	   , bank_account
	   , tip_name)
	SELECT VT.id
		 , VT.inn
		 , VT.bank_account
		 , VT.name
	FROM dbo.VOcc_types VT
	WHERE VT.id = @tip_id1

	UPDATE t
	SET fin_id = CASE
                     WHEN @fin_id1 IS NULL THEN ot.fin_id
                     ELSE @fin_id1
        END
	FROM @tip AS t
		JOIN dbo.Occupation_Types AS ot ON t.tip_id = ot.id

	-- для ограничения доступа услуг
	DECLARE @serv TABLE (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, name VARCHAR(100) COLLATE database_default
		, is_build BIT
	)
	INSERT INTO @serv
		(id
	   , name
	   , is_build)
	SELECT id
		 , name
		 , is_build
	FROM dbo.View_services
	WHERE is_counter = 1

	IF COALESCE(@serv_str, '') <> ''
		DELETE FROM @serv
		WHERE id NOT IN (
				SELECT Value
				FROM STRING_SPLIT(@serv_str, ',')
				WHERE RTRIM(Value) <> ''
			)
	IF @debug = 1
		SELECT *
		FROM @tip
	IF @debug = 1
		SELECT *
		FROM @serv

	;WITH cte AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY o.occ, c.serial_number ORDER BY (SELECT NULL)) AS row_sernum
		 , t.tip_name
		 , t.fin_id
		 , dbo.Fun_GetFalseOccOut(o.occ, t.tip_id) AS occ
		 , c.service_id
		 , s.short_name AS street
		 , b.nom_dom
		 , c.serial_number AS serial_number
		 , COALESCE(ci.inspector_date, ci_pred.inspector_date) AS last_date
		 , COALESCE(ci.inspector_value, ci_pred.inspector_value) AS last_value
		 , (ci.inspector_value - COALESCE(ci_pred.inspector_value, 0)) AS actual_value
		 , CASE
               WHEN c.PeriodCheck IS NULL THEN ''
               ELSE CONVERT(VARCHAR(10), c.PeriodCheck, 104)
        END AS period_poverki
		 , dbo.Fun_GetSberCounterTip(c.service_id, c.unit_id) AS counter_tip_sber
		 , c.id AS counter_id
		 , CAST(c.counter_uid AS VARCHAR(36)) AS counter_uid
		 , dbo.Fun_GetAdres(c.build_id, c.flat_id, o.occ) AS address
		 , COALESCE(o.id_els_gis, '') AS els
		 , CASE
               WHEN b.kod_fias IS NULL THEN ''
               ELSE b.kod_fias + ',' + f.nom_kvr
        END AS fias
		 , dbo.Fun_InitialsFull(o.occ) AS fio
		 , c.comments AS comments
		 , COALESCE(ao_build.inn, ao_tip.inn) AS inn  -- берём инн из расчетного счета
		 , COALESCE(ao_build.rasschet, ao_tip.rasschet) AS rasschet
	FROM dbo.Counters AS c 
		JOIN @serv AS serv ON 
			c.service_id = serv.id
		JOIN dbo.Buildings AS b ON 
			c.build_id = b.id
		JOIN dbo.Flats AS f ON 
			c.flat_id = f.id
		JOIN @tip AS t ON 
			b.tip_id = t.tip_id
		JOIN dbo.Occupations AS o ON 
			f.id = o.flat_id
		JOIN dbo.VStreets AS s ON 
			b.street_id = s.id
		LEFT JOIN dbo.Counter_list_all AS cl ON 
			t.fin_id = cl.fin_id
			AND cl.occ = o.occ
			AND c.id = cl.counter_id
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(c.id, t.fin_id) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(c.id, t.fin_id) AS ci_pred
		LEFT JOIN dbo.Account_org AS ao_tip ON 
			t.bank_account = ao_tip.id
		LEFT JOIN dbo.Account_org AS ao_build ON 
			b.bank_account = ao_build.id
	WHERE (b.id = @build_id1 OR @build_id1 IS NULL)
		AND c.date_edit BETWEEN COALESCE(@date1, c.date_edit) AND COALESCE(@date2, c.date_edit)
		AND (c.date_del IS NULL AND cl.occ IS NOT NULL)
		AND b.is_paym_build = 1
		AND o.total_sq > 0
		AND NOT EXISTS (
			SELECT *
			FROM [dbo].[Fun_GetTableBlockedExportPu](o.tip_id, b.id, c.service_id)
		)
	)
	SELECT t1.tip_name
		 , t1.inn
		 , t1.rasschet
		 , CONCAT(t1.Occ,';',MAX(t1.fio),';', MAX(t1.els),';', MAX(t1.fias),';', MAX(t1.address)) + (
			   SELECT CONCAT(t2.counter_tip_sber,';'
				   , t2.serial_number,';'
				   , t2.counter_uid,';'
				   , t2.period_poverki,';'
				   , REPLACE(dbo.FSTR(t2.last_value, 9, 2), ',', '.'),';'
				   , CASE
                         WHEN t2.last_date IS NULL THEN ''
                         ELSE CONVERT(VARCHAR(10), t2.last_date, 104)
                     END, ';'
				   , t2.comments,';'
				   )
			   FROM cte AS t2
			   WHERE t2.Occ = t1.Occ
			   FOR XML PATH ('')
		   ) AS pu_str
	FROM cte AS t1
	WHERE row_sernum = 1
	GROUP BY t1.tip_name
		   , t1.inn
		   , t1.rasschet
		   , t1.Occ
	ORDER BY t1.inn
		   , t1.rasschet
		   , t1.Occ
	--OPTION (MAXDOP 1, FAST 10)

	DROP TABLE IF EXISTS #cte;

END
go

