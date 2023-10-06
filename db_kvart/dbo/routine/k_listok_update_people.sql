CREATE   PROCEDURE [dbo].[k_listok_update_people]
(
	@owner_id1	INT
	,@id1		INT -- код листка прибытия(убытия)
)
AS
	/*

Берем данные по человеку из базы
для листка прибытия или убытия

*/
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 
				1
			FROM dbo.People_listok AS pl 
			WHERE id = @id1)
	BEGIN
		RAISERROR ('Не найден листок для изменения!', 16, 1)
		RETURN
	END

	-- Узнаем какой это листок
	DECLARE	@listok_id1	TINYINT
			,@occ1		INT
	SELECT
		@listok_id1 = listok_id
		,@occ1 = occ
	FROM dbo.People_listok AS pl 
	WHERE id = @id1

	UPDATE pl
	SET	last_name		= p.last_name
		,first_name		= p.first_name
		,second_name	= p.second_name
		,birthdate		= p.birthdate
		,owner_id		= p.id
		,sex			= p.sex
		,Citizen_id		= p.CITIZEN
		,Nationality	= p.Nationality
		,DOCTYPE_ID		= d.DOCTYPE_ID
		,doc_no			= d.doc_no
		,PASSSER_NO		= d.PASSSER_NO
		,ISSUED			= d.ISSUED
		,DOCORG			= d.DOCORG
		,kod_pvs		= d.kod_pvs
		,KraiBirth		= p2.KraiBirth
		,RaionBirth		= p2.RaionBirth
		,TownBirth		= p2.TownBirth
		,VillageBirth	= p2.VillageBirth
		,snils			= p.snils
	FROM dbo.PEOPLE_LISTOK AS pl , 
	dbo.PEOPLE AS p
	LEFT OUTER JOIN dbo.IDDOC AS d
		ON p.id = d.owner_id
		AND d.active = 1
	LEFT OUTER JOIN dbo.PEOPLE_2 AS p2
		ON p.id = p2.owner_id
	WHERE p.id = @owner_id1
	AND pl.id = @id1


	IF @listok_id1 = 1
	BEGIN -- листок прибытия
		UPDATE pl
		SET	KraiNew		= gb.Region
			,TownNew	= gb.Town
			,StreetNew	= b.street_short_name
			,Nom_domNew	= b.nom_dom_without_korp
			,Nom_krpNew = b.korp
			,Nom_kvrNew	= f.nom_kvr
		FROM dbo.PEOPLE_LISTOK AS pl
		JOIN dbo.OCCUPATIONS AS o 
			ON pl.occ = o.occ
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		JOIN dbo.View_BUILDINGS AS b 
			ON f.bldn_id = b.id
		JOIN dbo.GLOBAL_VALUES AS gb 
			ON o.fin_id = gb.fin_id
		WHERE pl.id = @id1
	END

	IF @listok_id1 = 2
	BEGIN -- листок Убытия
		UPDATE pl
		SET	KraiOld		= gb.Region
			,TownOld	= gb.Town
			,StreetOld	= b.street_short_name
			,Nom_domOld	= b.nom_dom_without_korp
			,Nom_krpOld = b.korp
			,Nom_kvrOld	= f.nom_kvr
		FROM dbo.PEOPLE_LISTOK AS pl
		JOIN dbo.OCCUPATIONS AS o 
			ON pl.occ = o.occ
		JOIN dbo.FLATS AS f
			ON o.flat_id = f.id
		JOIN dbo.View_BUILDINGS AS b 
			ON f.bldn_id = b.id
		JOIN dbo.GLOBAL_VALUES AS gb 
			ON o.fin_id = gb.fin_id
		WHERE pl.id = @id1

	END
go

