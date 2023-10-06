-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[rep_gis_paymaccount]
(
	@tip_id1		SMALLINT
	,@fin_id1		SMALLINT
	,@sup_id1		INT		= NULL
	,@build_id1		INT		= NULL
	,@tip_pay_id	VARCHAR(10)	= NULL
)
AS
/*
exec rep_gis_paymaccount @tip_id1=28, @fin_id1=187, @sup_id1=323, @build_id1=1047
exec rep_gis_paymaccount @tip_id1=109, @fin_id1=189, @sup_id1=null, @build_id1=null

*/
BEGIN
	SET NOCOUNT ON;

	SELECT
		ROW_NUMBER() OVER (ORDER BY day ASC, occ_sup) AS RowNum
		,*
	FROM (SELECT
			pp.day
			,p.value
			,RIGHT(CONVERT(VARCHAR(10), cp.start_date, 104),7) AS 'start_date'  --'MM.yyyy'
			,COALESCE(os.id_jku_gis, o.id_jku_gis) AS id_jku_gis
			,COALESCE(os.occ, o.occ) AS occ
			,COALESCE(sa.name, 'Нет') AS 'sup_name'
			,p.occ_sup
			,p.sup_id
			,vo.tip_paym AS tip_pay_name
			--,vo.tip_paym_id
			--,vo.description
			,vo.bank_name
		FROM dbo.PAYINGS p 
		JOIN dbo.PAYDOC_PACKS pp
			ON p.pack_id = pp.id
		JOIN dbo.View_PAYCOLL_ORGS vo
			ON pp.source_id = vo.id
		LEFT JOIN dbo.OCC_SUPPLIERS os 
			ON p.occ = os.occ
			AND pp.fin_id = os.fin_id
			AND pp.sup_id = os.sup_id
		JOIN dbo.CALENDAR_PERIOD cp 
			ON pp.fin_id = cp.fin_id
		JOIN dbo.OCCUPATIONS o 
			ON p.occ = o.occ
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		LEFT JOIN dbo.SUPPLIERS_ALL sa 
			ON os.sup_id = sa.id
		WHERE pp.tip_id = @tip_id1
		AND pp.fin_id = @fin_id1
		AND pp.forwarded = 1
		AND (pp.sup_id = @sup_id1
		OR @sup_id1 IS NULL)
		AND (f.bldn_id = @build_id1
		OR @build_id1 IS NULL)
		AND (vo.tip_paym_id = @tip_pay_id
		OR @tip_pay_id IS NULL)) AS t
	WHERE (sup_id = @sup_id1
	OR @sup_id1 IS NULL)
	ORDER BY [day], t.occ_sup
END
go

