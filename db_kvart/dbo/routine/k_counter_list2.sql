CREATE   PROCEDURE [dbo].[k_counter_list2]
(
	@counter_id1	INT
	,@fin_id1		SMALLINT	= NULL
)
AS
/*
	Список лицевых по заданному счетчику

	exec k_counter_list2 @counter_id1=64260
*/

	SET NOCOUNT ON


	SELECT
		cl.fin_id AS fin_id
		,dbo.Fun_NameFinPeriodDate(cl.start_date) AS fin_name
		,cl.counter_id
		,cl.occ
		,cl.service_id
		,cl.occ_counter
		,cl.internal
		,cl.no_vozvrat
		,cl.KolmesForPeriodCheck
		,CONCAT(RTRIM(O.address),' (',dbo.Fun_Initials(O.occ), ')') AS decription
		,o.id_els_gis
		,f.id_nom_gis
		,o.kol_people
	FROM dbo.View_counter_all AS cl 
		JOIN dbo.Occupations O ON cl.occ = O.occ
		JOIN dbo.Flats f ON O.flat_id = f.id
	WHERE cl.counter_id = @counter_id1
		AND (@fin_id1 IS NULL OR cl.fin_id = @fin_id1)
	ORDER BY fin_id DESC
go

