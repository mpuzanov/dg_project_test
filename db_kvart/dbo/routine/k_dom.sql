CREATE   PROCEDURE [dbo].[k_dom]
(
	@street_id1 INT		 = NULL
   ,@tip_id		SMALLINT = NULL
   ,@town_id	SMALLINT = NULL
)
AS
	/*
	k_dom 11,28
	
	*/
	SET NOCOUNT ON

	IF @street_id1 IS NULL
		AND @tip_id IS NULL
		AND @town_id IS NULL
		SET @street_id1 = 0

	SELECT
		b.nom_dom
	   ,b.ID
	   ,ot.name AS tip
	   ,tip_id
	   ,s.full_name AS street_name
	   ,b.fin_current
	   ,b.id_accounts
	   ,gv.StrMes AS StrFinPeriod
	   ,ra.FileName AS Account_name
	   ,CASE
			WHEN b.is_paym_build = CAST(0 AS BIT) THEN CAST(0 AS BIT)
			ELSE ot.payms_value
		END AS payms_value
	   ,b.town_id
	   ,ot.state_id
	   ,ot.only_read
	   ,CONCAT(s.full_name , ' д.' , b.nom_dom) AS name
	   ,t_flat.cntFlats	AS CountFlats
	   ,ot.only_pasport
	   ,CASE
			WHEN b.id_accounts IS NOT NULL THEN b.id_accounts
			ELSE ot.id_accounts
		END AS id_accounts
	   ,b.odn_big_norma -- Признак распределения ОДН более нормы
	   ,b.is_boiler -- Признак наличия бойлера
	   ,b.nom_dom_sort
	FROM dbo.BUILDINGS AS b
		JOIN dbo.GLOBAL_VALUES AS gv 
			ON gv.fin_id = b.fin_current
		JOIN dbo.Streets AS s
			ON b.street_id = s.ID
		JOIN dbo.VOCC_TYPES AS ot 
			ON b.tip_id = ot.ID
		LEFT JOIN dbo.reports_account AS ra 
			ON b.id_accounts = ra.ID
		OUTER APPLY (SELECT	COUNT(F.ID) AS cntFlats	
					FROM dbo.FLATS AS F
					WHERE F.bldn_id = b.ID) as t_flat
	WHERE (@street_id1 IS NULL OR b.street_id = @street_id1)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@town_id IS NULL OR b.town_id = @town_id)
	ORDER BY s.NAME
	, b.nom_dom_sort
	, ot.payms_value DESC
go

