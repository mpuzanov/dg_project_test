CREATE   PROCEDURE [dbo].[k_listok_show_print]
(
	@id1			INT
	,@printdoc1		BIT			= 1 -- печатаем паспортные данные
	,@owner_id		INT			= NULL
	,@listok_tip	SMALLINT	= 1
)
AS
	/*

Показываем информацию для печати листка прибытия или убытия
k_listok_show_print @id1=0,@owner_id=213378
k_listok_show_print @id1=0,@owner_id=13402
k_listok_show_print @id1=0,@owner_id=1099569

*/
	SET NOCOUNT ON
	DECLARE	@occ1		INT
			,@id_new	INT			= 0
			,@str1		VARCHAR(50)	= ''

	IF @printdoc1 IS NULL
		SET @printdoc1 = 1

	IF @id1 = 0
		AND @owner_id > 0
	BEGIN

		SELECT
			@occ1 = occ
		FROM dbo.PEOPLE 
		WHERE id = @owner_id
		--PRINT @listok_tip		
		IF @occ1 IS NULL
			RETURN -1
		EXEC dbo.k_listok_add	@occ1
								,@listok_tip
								,@id_new OUT
		--PRINT @id_new
		IF @id_new = 0
			RETURN -1
		EXEC k_listok_update_people	@owner_id
									,@id_new
		SET @id1 = @id_new

	END
	ELSE
	BEGIN
		SELECT
			@listok_tip = listok_id
		FROM dbo.People_listok AS pl 
		WHERE id = @id1
	END

	SELECT
		pl.*
		,CI.name                                                                                                AS Citizen_name
		,DT.name                                                                                                AS DOC_NAME
		,DT.short_name                                                                                          AS DOC_short_name
		,Town3 = @str1
		,Street3 = @str1
		,Nom_dom3 = @str1
		,Nom_kvr3 = @str1
		,Adres4 = @str1
		--,dbo.Fun_Dat(RTRIM(last_name) + ' ' + RTRIM(first_name) + ' ' + RTRIM(second_name)) AS FIOdat
		--,dbo.Fun_Падеж(RTRIM(last_name) + ' ' + RTRIM(first_name) + ' ' + RTRIM(second_name), 'Р', NULL) AS FIOrod
		,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Д', CASE
                                                                        WHEN sex = 1 THEN 'МУЖ'
                                                                        ELSE CASE
                                                                                 WHEN sex = 0 THEN 'ЖЕН'
                                                                                 ELSE NULL
                                                                            END
        END) AS FIOdat
		,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Р', CASE
                                                                        WHEN sex = 1 THEN 'МУЖ'
                                                                        ELSE CASE
                                                                                 WHEN sex = 0 THEN 'ЖЕН'
                                                                                 ELSE NULL
                                                                            END
        END) AS FIOrod
	INTO #t1
	FROM dbo.PEOPLE_LISTOK AS pl 
	LEFT JOIN dbo.IDDOC_TYPES DT 
		ON DT.id = pl.DOCTYPE_ID
	LEFT JOIN dbo.CITIZEN CI 
		ON CI.id = pl.Citizen_id
	WHERE pl.id = @id1

	UPDATE #t1
	SET sex = COALESCE(sex, 100)

	UPDATE t
	SET	KraiOld						= t2.KraiOld
		,RaionOld					= t2.RaionOld
		,TownOld					= t2.TownOld
		,VillageOld					= t2.VillageOld
		,StreetOld					= t2.StreetOld
		,Nom_domOld					= t2.nom_domOld_without_korp
		,Nom_kvrOld					= t2.Nom_kvrOld
		,KraiNew					= t2.KraiNew
		,RaionNew					= t2.RaionNew
		,TownNew					= t2.TownNew
		,VillageNew					= t2.VillageNew
		,StreetNew					= t2.StreetNew
		,Nom_domNew					= t2.nom_domNew_without_korp
		,Nom_kvrNew					= t2.Nom_kvrNew
		,KraiBirth					= t2.KraiBirth
		,RaionBirth					= t2.RaionBirth
		,TownBirth					= t2.TownBirth
		,VillageBirth				= t2.VillageBirth
		,Nom_krpOld					= t2.korpOld
		,Nom_krpNew					= t2.korpNew
	FROM #t1 AS t
	JOIN dbo.View_PEOPLE2 AS t2
		ON t.owner_id = t2.owner_id

	IF @listok_tip = 1
		UPDATE #t1
		SET Adres4 = SUBSTRING(TownOld + ', ' + StreetOld + ' ' + Nom_domOld + '-' + Nom_kvrOld, 1, 50)
	ELSE
		UPDATE #t1
		SET Adres4 = SUBSTRING(TownNew + ', ' + StreetNew + ' ' + Nom_domNew + '-' + Nom_kvrNew, 1, 50)

	IF @printdoc1 = 0
	BEGIN
		UPDATE #t1
		SET
		--DOC_NAME='',
		DOC_NO		= ''
		,PASSSER_NO	= ''
		,ISSUED		= NULL
		,DOCORG		= ''
	END
	--SELECT * FROM dbo.#t1 AS t

	-- если совпадает населённый пункт
	IF EXISTS (SELECT
				1
			FROM #t1
			WHERE COALESCE(TownOld, '') = COALESCE(TownNew, ''))
		OR EXISTS (SELECT
				1
			FROM #t1
			WHERE COALESCE(KraiOld, '') = ''
			AND COALESCE(RaionOld, '') = ''
			AND COALESCE(TownOld, '') = ''
			AND COALESCE(VillageOld, '') = '')
	BEGIN
		IF @listok_tip = 1 -- листок прибытия
		BEGIN
			UPDATE #t1
			SET	Town3						= TownOld
				,Street3					= StreetOld
				,Nom_dom3					= Nom_domOld
				,Nom_kvr3					= Nom_kvrOld
				,Adres4						= TownOld + ', ' + StreetOld + ' ' + Nom_domOld + '-' + Nom_kvrOld
				,KraiOld					= ''
				,RaionOld					= ''
				,TownOld					= ''
				,VillageOld					= ''
				,StreetOld					= ''
				,Nom_domOld					= ''
				--,Nom_domOld_without_korp	= ''
				,Nom_krpOld					= ''
				,Nom_kvrOld					= ''
		END

		IF @listok_tip = 2 -- листок убытия
		BEGIN
			UPDATE #t1
			SET	Town3						= TownNew
				,Street3					= StreetNew
				,Nom_dom3					= Nom_domNew
				,Nom_kvr3					= Nom_kvrNew
				,Adres4						= SUBSTRING(TownNew + ', ' + StreetNew + ' ' + Nom_domNew + '-' + Nom_kvrNew, 1, 50)
				,KraiNew					= ''
				,RaionNew					= ''
				,TownNew					= ''
				,VillageNew					= ''
				,StreetNew					= ''
				,Nom_domNew					= ''
				--,Nom_domNew_without_korp	= ''
				,Nom_krpNew					= ''
				,Nom_kvrNew					= ''

			-- текущий адрес  
			UPDATE t
			SET	KraiOld						= ''
				,RaionOld					= ''
				,TownOld					= T1.name
				,VillageOld					= ''
				,StreetOld					= S.name
				,Nom_domOld					= B.nom_dom
				,Nom_kvrOld					= F.nom_kvr
				--,Nom_domOld_without_korp	= B.nom_dom_without_korp
				,Nom_krpOld					= B.korp
			FROM #t1 AS t
			JOIN dbo.OCCUPATIONS AS O 
				ON O.occ = t.occ
			JOIN dbo.FLATS AS F 
				ON F.id = O.flat_id
			JOIN dbo.View_BUILDINGS AS B 
				ON B.id = F.bldn_id
			JOIN dbo.VSTREETS AS S 
				ON S.id = B.street_id
			JOIN dbo.TOWNS AS T1 
				ON T1.id = B.town_id
		END

	END

	SELECT
		*
	FROM #t1
	DROP TABLE #t1

	IF @id_new > 0
		DELETE FROM dbo.PEOPLE_LISTOK 
		WHERE id = @id_new
go

