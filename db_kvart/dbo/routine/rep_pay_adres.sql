CREATE   PROCEDURE [dbo].[rep_pay_adres]
(
	@date1		DATETIME	= NULL
	,@date2		DATETIME	= NULL
	,@bank_id1	INT			= NULL
	,@tip		SMALLINT	= NULL
	,@fin_id1	SMALLINT	= NULL
	,@sup_id	INT			= NULL
)
AS
	/*
	  Протокол ввода платежей
	  по адресам
	  
	  01.03.2012
	*/

	SET NOCOUNT ON

	IF @date2 IS NULL
		SET @date2 = @date1

	IF @bank_id1 = 0
		SET @bank_id1 = NULL

	IF @fin_id1 IS NULL
		AND @date1 IS NULL
		AND @date2 IS NULL
		AND @tip IS NULL
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)
			,@tip = 0

	IF @fin_id1 IS NOT NULL
		SELECT
			@date1 = '19000101'
			,@date2 = '20500101'

	SELECT
		p.occ
		,p.value
		,p.paymaccount_peny
		,p.pack_id
		,p.day
		,p.source_name AS orgs
		,p.[description] AS [description]
		,dbo.Fun_GetOnlyDate(p.date_edit) AS date_edit
		,p.id
		,p.tip_paym
		,ba.street_name
		,ba.nom_dom
		,f.nom_kvr
		,ba.bldn_id
		,dog.dog_id
	FROM dbo.View_payings AS p 
	JOIN dbo.VPaycol_user AS vp
		ON p.ext = vp.ext
	JOIN dbo.VOCC AS o 
		ON p.occ = o.occ 
	JOIN dbo.Flats AS f 
		ON o.flat_id = f.id
	LEFT JOIN dbo.View_BUILD_ALL AS ba 
		ON p.fin_id = ba.fin_id
		AND f.bldn_id = ba.bldn_id
	LEFT JOIN dbo.DOG_SUP AS dog 
		ON p.dog_int = dog.id
	WHERE 
		p.day BETWEEN @date1 AND @date2
		AND p.tip_id = COALESCE(@tip, p.tip_id)
		AND p.forwarded = 1
		AND p.bank_id = COALESCE(@bank_id1, p.bank_id)
		AND p.fin_id = COALESCE(@fin_id1, p.fin_id)
		AND (p.sup_id = @sup_id	OR @sup_id IS NULL)
	ORDER BY ba.street_name, ba.nom_dom_sort, f.nom_kvr_sort
	OPTION (MAXDOP 1);
go

