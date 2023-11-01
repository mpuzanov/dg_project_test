CREATE   PROCEDURE [dbo].[adm_add_servunits]
(
	@fin_id1	  SMALLINT -- фин.период
   ,@tip_id1	  SMALLINT -- тип жилого фонда  
   ,@service_id1  VARCHAR(10) -- код услуги
   ,@roomtype_id1 VARCHAR(10)	= NULL
   ,@unit_id1	  VARCHAR(10)	= NULL
   ,@unit_str	  NVARCHAR(MAX) = NULL -- строка формата: тип квартиры:ед.измерения;тип квартиры:ед.измерения (отдк:кубм;комм:кубм;об10:кубм;об06:кубм)
)
AS
	/*
	Изменяем еденицы измерения услуг
	adm_add_servunits 212, 28, 'площ', 'отдк', 'оквм'

	adm_add_servunits 212, 28, 'площ', NULL, NULL, 'отдк:оквм;комм:оквм;об10:оквм;об06:оквм'

	adm_add_servunits 212, 28, 'врег', NULL, NULL, 'отдк:;комм:оквм;об10:;об06:'
	adm_add_servunits 212, 28, 'вотд', NULL, NULL, 'отдк:одс2;комм:оквм;об10:одс2;об06:одс2'

	бокс,парк,клад,об06,комм,коля,отдк,офис,об10

	*/

	SET NOCOUNT ON


	-- Таблица с услугами
	DECLARE @t_units TABLE
		(
			roomtype_id VARCHAR(10)
		   ,unit_id		VARCHAR(10) NOT NULL
		)
	IF dbo.strpos(':', @unit_str) > 0
	BEGIN
		INSERT
		INTO @t_units
		(roomtype_id
		,unit_id)
			SELECT
				id
			   ,val
			FROM dbo.Fun_split_IdValue(@unit_str, ';')
			WHERE val > ''
	END
	ELSE
	BEGIN
		INSERT
		INTO @t_units
		(roomtype_id
		,unit_id)
		VALUES (@roomtype_id1
			   ,@unit_id1)
	END

	--SELECT * FROM @t_units

	--SELECT
	--		@fin_id1
	--	   ,@tip_id1
	--	   ,@service_id1
	--	   ,roomtype_id
	--	   ,unit_id
	--	FROM @t_units

	MERGE Service_units AS target USING (SELECT
			@fin_id1
		   ,@tip_id1
		   ,@service_id1
		   ,roomtype_id
		   ,unit_id
		FROM @t_units) AS source (fin_id, tip_id, service_id, roomtype_id, unit_id)
	ON (target.fin_id = source.fin_id
		AND target.tip_id = source.tip_id
		AND target.service_id = source.service_id
		AND target.roomtype_id = source.roomtype_id)
	WHEN MATCHED
		THEN UPDATE
			SET unit_id = source.unit_id
	WHEN NOT MATCHED
		THEN INSERT
			(fin_id
			,tip_id
			,service_id
			,roomtype_id
			,unit_id)
			VALUES (source.fin_id
				   ,source.tip_id
				   ,source.service_id
				   ,source.roomtype_id
				   ,source.unit_id)
	OUTPUT $ACTION
		  ,INSERTED.*
		  ,DELETED.*;-- INTO #MyTempTable;

	--SELECT
	--	*
	--FROM #MyTempTable
go

