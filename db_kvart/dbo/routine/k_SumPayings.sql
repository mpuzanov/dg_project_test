CREATE   PROCEDURE [dbo].[k_SumPayings]
(
	@pack_id1	INT  -- номер пачки
	,@total1	MONEY	= NULL -- сумма по пачке (должна быть)
)
AS
	SET NOCOUNT ON

	DECLARE	@docsnum		INT  -- должно быть документов
			,@KolDocs		INT  -- введено документов
			,@VSumma		DECIMAL(15, 2)
			,@RSumma		DECIMAL(15, 2)
			,@Commission	DECIMAL(15, 2)
			,@VCommission	DECIMAL(15, 2)
			,@RCommission	DECIMAL(15, 2)
			,@Sup_name		VARCHAR(50)

	SELECT
		@docsnum = docsnum
		,@total1 = total
		,@Commission = COALESCE(commission, 0)
		,@Sup_name = sa.name
	FROM dbo.PAYDOC_PACKS AS PP
	LEFT JOIN dbo.SUPPLIERS_ALL AS sa 
		ON PP.sup_id = sa.id
	WHERE PP.id = @pack_id1

	SELECT
		@KolDocs = COUNT(id)
		,@VSumma = SUM(value)
		,@VCommission = SUM(COALESCE(commission, 0))
	FROM dbo.PAYINGS 
	WHERE pack_id = @pack_id1

	SELECT
		@RSumma = @total1 - @VSumma
		,@RCommission = @Commission - @VCommission

	SELECT
		@KolDocs AS KolDocs
		,COALESCE(@VSumma,0) AS VSumma
		,COALESCE(@VCommission,0) AS VCommission
		,COALESCE(@RSumma,0) AS RSumma
		,COALESCE(@RCommission,0) as RCommission
		,@Sup_name AS Sup_name
go

