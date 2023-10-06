-- =============================================
-- Author:		Пузанов
-- Create date: 24/10/2008
-- Description:	Список домов для отчетов
-- =============================================
CREATE         PROCEDURE [dbo].[rep_buildings]
(
	  @tip_id SMALLINT = NULL
	, @town_id SMALLINT = NULL
	, @is_only_paym BIT = NULL
)
/*

exec rep_buildings @tip_id,@town_id
exec rep_buildings @tip_id=1, @is_only_paym=1

*/
AS
BEGIN
	SET NOCOUNT ON;


	SELECT *
	FROM (
		SELECT TOP (9999) b.Id
					  , CONCAT(RTRIM(s.full_name) , ' ' , RTRIM(b.nom_dom) , '; ' + RTRIM(t.name)) AS name
					  , CONCAT(RTRIM(s.name) , ' д.' , RTRIM(b.nom_dom)) AS [address]
					  , b.tip_id
					  , CAST(CASE
							WHEN (t.payms_value = CAST(0 AS BIT) OR b.is_paym_build = CAST(0 AS BIT)) THEN 0
							ELSE 1
						END AS BIT) AS is_paym
		FROM dbo.Buildings AS b 
			JOIN dbo.Streets AS s ON 
				s.Id = b.street_id
			JOIN dbo.VOcc_types AS t ON 
				t.Id = b.tip_id
		WHERE 
			(@tip_id IS NULL OR b.tip_id = @tip_id)
			AND (@town_id IS NULL OR b.town_id = @town_id)
			AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
			AND (@is_only_paym IS NULL OR t.payms_value = @is_only_paym)
		ORDER BY s.name
			   , b.nom_dom_sort
	) AS T
	UNION ALL
	SELECT NULL AS id
		 , '<Все>' AS name
		 , '<Все>' AS [address]
		 , NULL AS tip_id
		 , CAST(1 AS BIT) AS is_paym


END
go

