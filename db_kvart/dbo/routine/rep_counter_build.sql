-- =============================================
-- Author:		Пузанов
-- Create date: 06/10/2011
-- Description:	Реестр домовых счётчиков
-- =============================================
CREATE       PROCEDURE [dbo].[rep_counter_build]
@tip_id SMALLINT=NULL,
@service_id VARCHAR(10)=NULL,
@build_id INT = NULL,
@town_id SMALLINT = null
AS
BEGIN
	SET NOCOUNT ON;

	
	DECLARE @fin_current SMALLINT	
	SELECT @fin_current=dbo.Fun_GetFinCurrent(@tip_id,@build_id,NULL,NULL)

	
	SELECT 
		cl.*
		,serv.short_name AS service_name
		, b.town_name
		, B.tip_name
		, B.adres AS 'Адрес дома'
		, cl.nom_dom AS 'Номер дома'
	FROM dbo.View_COUNTER_BUILD AS cl 
		JOIN dbo.View_SERVICES AS serv ON cl.service_id=serv.id
		JOIN dbo.View_BUILDINGS AS B ON cl.build_id=B.id
	WHERE 1=1
		AND (@tip_id IS null OR cl.tip_id=@tip_id)
		AND cl.date_del IS NULL
		AND (@build_id IS null OR cl.build_id=@build_id)
		AND (@service_id IS null OR cl.service_id=@service_id)
		AND (@town_id IS null OR b.town_id=@town_id)
	ORDER BY b.town_name, cl.Street_name, cl.nom_dom_sort
	

END
go

