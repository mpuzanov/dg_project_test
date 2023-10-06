CREATE   PROCEDURE [dbo].[rep_ivc_occ]
(
	  @tip_id SMALLINT = NULL
	, @fin_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @is_only_paym BIT = NULL
	, @debug BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
BEGIN
/*
Выгрузка лиц.счетов
    	
exec rep_ivc_occ @tip_id=5, @fin_id=232, @build_id=null, @debug=0, @format='xml'
exec rep_ivc_occ @tip_id=1, @fin_id=244, @build_id=null, @sup_id=345, @debug=0
exec rep_ivc_occ @tip_id=1, @fin_id=236, @build_id=null, @sup_id=null, @debug=0
*/

	SET NOCOUNT ON;


	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL);

	DROP TABLE IF EXISTS #t_occ;
	CREATE TABLE #t_occ (
		  UID_Dom VARCHAR(36) --UNIQUEIDENTIFIER
		, UID_Pomesheniya VARCHAR(36) --UNIQUEIDENTIFIER
		, UID_LC VARCHAR(36) --UNIQUEIDENTIFIER
		, nomerls INT
		, LC_Nomer INT
		, Area DECIMAL(5, 2)
		, Sobstvenik_Kolichectvo SMALLINT
		, Propisano SMALLINT
		, Progivaet SMALLINT
		, Tip_LC VARCHAR(20) COLLATE database_default DEFAULT 'ЖКУ'
		, email VARCHAR(50) COLLATE database_default DEFAULT ''
		, phone VARCHAR(50) COLLATE database_default DEFAULT ''		
	)

	INSERT INTO #t_occ(UID_Dom,UID_Pomesheniya,UID_LC,nomerls,LC_Nomer,Area,Sobstvenik_Kolichectvo,Propisano,Progivaet,Tip_LC,email,phone)
	SELECT b.build_uid AS UID_Dom
		 , f.flat_uid AS UID_Pomesheniya
		 , o.occ_uid AS UID_LC
		 , o.occ AS nomerls
		 , dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS LC_Nomer
		 , o.total_sq AS Area
		 , COALESCE(o.kol_people_owner, 0) AS Sobstvenik_Kolichectvo
		 , COALESCE(o.kol_people_reg, 0) AS Propisano
		 , COALESCE(o.kol_people, 0) AS Progivaet
		 , 'ЖКУ' AS Tip_LC
		 , o.email
		 , CAST(o.telephon AS VARCHAR(50))
	FROM dbo.View_occ_main AS o
		JOIN dbo.Buildings AS b ON 
			o.build_id = b.id
		JOIN dbo.Flats AS f ON 
			o.flat_id = f.id
	WHERE 
		o.fin_id = @fin_id
		AND (o.tip_id = @tip_id OR @tip_id IS NULL)
		AND (o.build_id = @build_id OR @build_id IS NULL)
		AND o.status_id <> 'закр'
		AND o.total_sq > 0
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)

	INSERT INTO #t_occ(UID_Dom,UID_Pomesheniya,UID_LC,nomerls,LC_Nomer,Area,Sobstvenik_Kolichectvo,Propisano,Progivaet,Tip_LC)
	SELECT o.UID_Dom
		 , o.UID_Pomesheniya
		 , os.occ_sup_uid AS UID_LC
		 , os.occ AS nomerls
		 , os.occ_sup AS LC_Nomer
		 , o.Area
		 , o.Sobstvenik_Kolichectvo
		 , o.Propisano
		 , o.Progivaet
		 , dbo.Fun_GetTip_nachisleniya_buffer(sup.tip_occ) AS Tip_LC
	FROM #t_occ AS o
		JOIN dbo.Occ_Suppliers AS os ON 
			os.fin_id = @fin_id
			AND os.occ = o.nomerls
		JOIN dbo.Suppliers_all AS sup ON 
			os.sup_id = sup.id
			AND sup.tip_occ = 3
			AND sup.account_one = CAST(1 AS BIT)
	
	/*
	получение собственников по л/сч
	Добавляем: Собственник ФИО (name,surname, patronymic) 
	Паспорт серия (passport_series), Паспорт номер (passport_number), Код подразделения (passport_code), 
	Эл. почта (email), Телефон (phone)
	
	surname
	name
	patronymic
	passport_number
	passport_series	
	passport_code
	email
	phone

	select o.*, t.*
	from #t_occ AS o
	OUTER APPLY (select top(1) * from dbo.Fun_GetTableOwnerOcc(o.nomerls) as t1 ORDER BY t1.Birthdate DESC) as t
	*/	

	IF @format IS NULL OR @format NOT IN ('xml','json')
		select o.*, 
		t.Last_name AS surname,
		t.First_name AS [name],
		t.Second_name AS patronymic,
		t.doc_no AS passport_number,
		t.passser_no AS passport_series,
		t.kod_pvs AS passport_code
		from #t_occ AS o
		OUTER APPLY (select top(1) * from dbo.Fun_GetTableOwnerOcc(o.nomerls) as t1 ORDER BY t1.Birthdate DESC) as t
		--SELECT * FROM #t_occ

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				select o.*, 
						t.Last_name AS surname,
						t.First_name AS [name],
						t.Second_name AS patronymic,
						t.doc_no AS passport_number,
						t.passser_no AS passport_series,
						t.kod_pvs AS passport_code
				from #t_occ AS o
				OUTER APPLY (select top(1) * from dbo.Fun_GetTableOwnerOcc(o.nomerls) as t1 ORDER BY t1.Birthdate DESC) as t
				FOR XML PATH ('lic_chet'), ELEMENTS, ROOT ('licevie_scheta')

				--SELECT * FROM #t_occ FOR XML PATH ('lic_chet'), ELEMENTS, ROOT ('licevie_scheta')
			) AS result
	IF @format = 'json'
		SELECT (
				select o.*, 
						t.Last_name AS surname,
						t.First_name AS [name],
						t.Second_name AS patronymic,
						t.doc_no AS passport_number,
						t.passser_no AS passport_series,
						t.kod_pvs AS passport_code
				from #t_occ AS o
				OUTER APPLY (select top(1) * from dbo.Fun_GetTableOwnerOcc(o.nomerls) as t1 ORDER BY t1.Birthdate DESC) as t
				FOR JSON PATH, ROOT ('licevie_scheta')

				--SELECT * FROM #t_occ FOR JSON PATH, ROOT ('licevie_scheta')
			) AS result

DROP TABLE IF EXISTS #t_occ;
/*
<licevie_scheta>
	<period>09.2020</period>
	<lic_chet>
		<UID_Dom>5289bd5a-f14d-11e3-9b2a-1c6f65e34def</UID_Dom>
		<UID_pomeshenie>d0eb6e44-0c59-11ea-8035-902b341af037</UID_pomeshenie>
		<UID_LC>bcd83355-0c59-11ea-8035-902b341af037</UID_LC>
		<nomerls>34136</nomerls>
		<LC_Nomer>350034136</LC_Nomer>
		<Area>63,7</Area>
		<Sobstvenik_Kolichectvo>0</Sobstvenik_Kolichectvo>
		<Propisano>4</Propisano>
		<Progivaet>4</Progivaet>
		<Tip_LC>ЖКУ</Tip_LC>
	</lic_chet>
*/
END;
go

