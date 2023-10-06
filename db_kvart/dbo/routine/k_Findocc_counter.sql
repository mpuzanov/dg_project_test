CREATE   PROCEDURE [dbo].[k_Findocc_counter]
(
	@occ1				INT			= NULL -- лицевой
	,@counter_id1		INT			= NULL -- код счетчика
	,@serial_number1	VARCHAR(20)	= NULL -- серийный номер счетчика
	,@flat_id1			INT			= NULL -- код квартиры
	,@id_pu_gis1		VARCHAR(15)	= NULL -- код ПУ в ГИС ЖКХ
	,@id_els_gis1		VARCHAR(15)	= NULL -- ЕЛС в ГИС ЖКХ
	,@id_nom_gis1		VARCHAR(15)	= NULL -- Код помещения в ГИС ЖКХ
)
AS
	/*
	По лицевому или коду счетчика находим: Улицу, Дом, Квартиру
	
	дата создания: 10.06.2004
	автор: Пузанов М.А.
	
	дата последней модификации: 5/01/05
	автор изменений:
	
	добавил поиск по коду
	добавил поиск по серийному номеру 14.07.2006
	
	изменил на JOIN 17/09/2009

	exec k_Findocc_counter @counter_id1=134214

	*/
	SET NOCOUNT ON

	IF @occ1 IS NULL
		AND @counter_id1 IS NULL
		AND @serial_number1 IS NULL
		AND @flat_id1 IS NULL
		AND @id_pu_gis1 IS NULL
		AND @id_nom_gis1 IS NULL
		SET @occ1 = 0

	IF (@occ1>0 OR @id_els_gis1 IS NOT NULL)
	BEGIN
		SELECT TOP 1
			cl.Occ
			,b.street_id
			,b.id AS [build_id]
			,b.nom_dom
			,f.id AS [flat_id]
			,f.nom_kvr
			,b.tip_id
			,cl.counter_id
			,c.date_del
		FROM dbo.OCCUPATIONS AS o
		JOIN dbo.FLATS AS f
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS AS b 
			ON f.bldn_id = b.id
		JOIN dbo.COUNTER_LIST_ALL AS cl 
			ON cl.Occ = o.Occ
		JOIN dbo.COUNTERS c 
			ON c.id=cl.counter_id
		WHERE (cl.Occ = @occ1 AND @id_els_gis1 IS NULL)
		OR (o.id_els_gis=@id_els_gis1 AND @occ1=0)
		ORDER BY c.date_del
	END
	ELSE
	BEGIN
		SELECT TOP 1
			occ = NULL
			,b.street_id
			,b.id AS [build_id]
			,b.nom_dom
			,f.id AS [flat_id]
			,f.nom_kvr
			,b.tip_id
			,c.id AS counter_id
			,c.date_del
		FROM dbo.COUNTERS AS c 
		LEFT JOIN dbo.FLATS AS f 
			ON c.flat_id = f.id
		JOIN dbo.BUILDINGS AS b 
			ON c.build_id = b.id
		WHERE (c.id = @counter_id1 OR @counter_id1 IS NULL)
		AND	(c.serial_number = @serial_number1 OR @serial_number1 IS NULL)
		AND (c.flat_id = @flat_id1 OR @flat_id1 IS NULL)
		AND (c.id_pu_gis = @id_pu_gis1 OR @id_pu_gis1 IS NULL)
		AND (f.id_nom_gis = @id_nom_gis1 OR @id_nom_gis1 IS NULL)
	END
go

