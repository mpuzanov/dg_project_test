CREATE   PROCEDURE [dbo].[rep_counter_show]
(
	@tip_id1		SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@build_id1		INT			= NULL
	,@service_id1	VARCHAR(10)	= NULL
)

/*
Список счетчиков

автор:		    Пузанов
дата создания:	02.11.2010
дата изменеия:	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	
*/
AS

	SET NOCOUNT ON


	SELECT
		s.name
		,b.nom_dom
		,f.nom_kvr
		,c.*
	FROM dbo.COUNTERS AS c
	JOIN dbo.FLATS AS f 
		ON c.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	WHERE (@build_id1 IS NULL OR b.id = @build_id1)
		AND (@div_id1 IS NULL OR b.div_id = @div_id1)
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@service_id1 IS NULL OR c.service_id = @service_id1)
	ORDER BY name, nom_dom_sort, nom_kvr_sort
go

