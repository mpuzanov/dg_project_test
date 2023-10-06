CREATE   PROCEDURE [dbo].[rep_pay_2]
(
	  @date1 DATETIME = NULL
	, @date2 DATETIME = NULL
	, @bank_id1 INT = NULL
	, @tip SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @sup_id INT = NULL
)
AS
	/*
	  Протокол ввода платежей
	
	*/

	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	IF @date2 IS NULL
		SET @date2 = @date1
	IF @tip = 0
		SET @tip = NULL
	IF @bank_id1 = 0
		SET @bank_id1 = NULL

	IF @fin_id1 IS NULL
		AND @date1 IS NULL
		AND @date2 IS NULL
		SET @fin_id1 = @fin_current

	IF @fin_id1 IS NOT NULL
		SELECT @date1 = '19000101'
			 , @date2 = '20500101'


	SELECT p2.occ
		 , p2.value
		 , p1.id AS pack_id
		 , p1.day
		 , po.bank_name AS orgs
		 , dbo.Fun_Initials(p2.occ) AS Initials
		 , po.description
		 , dbo.Fun_GetOnlyDate(p1.date_edit) AS date_edit
		 , p2.id
		 , po.tip_paym AS tip_paym
	FROM dbo.Paydoc_packs AS p1
		JOIN dbo.Payings AS p2 ON p2.pack_id = p1.id
		JOIN dbo.View_paycoll_orgs AS po ON po.id = p1.source_id
			AND po.fin_id = p1.fin_id
	WHERE p1.day BETWEEN @date1 AND @date2
		AND p1.tip_id = COALESCE(@tip, p1.tip_id)
		AND p1.checked = 1
		AND p1.forwarded = 1
		AND po.bank_id = COALESCE(@bank_id1, po.bank_id)
		AND p1.fin_id = COALESCE(@fin_id1, p1.fin_id)
		AND (p1.sup_id = @sup_id OR @sup_id IS NULL)
	ORDER BY p1.day
		   , p2.occ
go

