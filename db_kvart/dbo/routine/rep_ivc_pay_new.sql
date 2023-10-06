-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Платежи
-- =============================================
CREATE         PROCEDURE [dbo].[rep_ivc_pay_new]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*
По Платежам

rep_ivc_pay_new @fin_id=176,@tip_id=28,@build_id=1031,@format='xml'
rep_ivc_pay_new @fin_id=232,@tip_id=1,@build_id=null,@sup_id=345
rep_ivc_pay_new @fin_id=232,@tip_id=1,@build_id=null,@sup_id=null

*/
BEGIN
	SET NOCOUNT ON;



	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL);

	SELECT CASE
               WHEN o.sup_id > 0 THEN o.Occ
               ELSE dbo.Fun_GetFalseOccOut(o.Occ, o.tip_id)
        END AS 'LC_Nomer'
		 , o.PaymAccount AS 'Nachisleno'
		 , CASE
               WHEN sup.tip_occ = 3 THEN 'Кап. ремонт'
               ELSE 'ЖКУ'
        END AS Tip_nachisleniya
		   --, CAST(pd.day AS DATE) AS 'Data_platega'
		 , CAST(gb.start_date AS DATE) AS 'Data_platega'
		 , o.Paymaccount_Serv AS 'Nachisleno_Uslig'
		 , o.PaymAccount_peny AS 'Nachisleno_Peni'
	INTO #t
	FROM dbo.View_occ_and_sup o
		JOIN dbo.Global_values AS gb ON 
			o.fin_id = gb.fin_id
		LEFT JOIN dbo.Suppliers_all AS sup ON 
			o.sup_id = sup.id
			AND sup.tip_occ IN (1, 3)
		JOIN dbo.Flats f ON 
			o.flat_id = f.id
		JOIN dbo.Buildings b ON 
			f.bldn_id = b.id
	WHERE 1=1
		AND o.fin_id = @fin_id
		AND (@tip_id IS NULL OR o.tip_id = @tip_id)
		AND (@sup_id IS NULL OR o.sup_id = @sup_id)
		AND (@build_id IS NULL OR b.id = @build_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym) 
		AND o.PaymAccount <> 0



	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>' + (
				SELECT *
				FROM #t
				FOR XML PATH ('oplata_LC'), ELEMENTS, ROOT ('oplati')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('oplati')
			) AS result

DROP TABLE IF EXISTS #t;

/*
<oplati>
	<oplata_LC>
		<UID_LC>62044a8c-f14d-11e3-9b2a-1c6f65e34def</UID_LC>
		<LC_Nomer>350033039</LC_Nomer>
		<Nachisleno>0,02</Nachisleno>
		<Tip_nachisleniya>ฦสำ</Tip_nachisleniya>
		<Data_platega/>
		<Nachisleno_Uslig>0,02</Nachisleno_Uslig>
		<Nachisleno_Peni>0</Nachisleno_Peni>
	</oplata_LC>
</oplati>
*/

END
go

