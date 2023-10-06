CREATE   PROCEDURE [dbo].[ka_opu_add]
(
	@occ1			INT
	,@service_id1	VARCHAR(10)
	,@kol			DECIMAL(9, 4)	= 0
	,@value			DECIMAL(9, 2)	= 0
	,@comments		VARCHAR(100)	= NULL
	,@unit_id		VARCHAR(10)		= NULL
	,@tarif			DECIMAL(10, 4)	= 0
	,@KolAdd		INT				= 0 OUTPUT -- количество добавленно
)
AS
	/*
Дата создания: 15/09/2012

   Добавляем разовые(начисления) по общедомовым приборам учёта по лицевым
   
*/
	SET NOCOUNT ON

	DECLARE @fin_id1 SMALLINT
	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF NOT EXISTS (SELECT
				*
			FROM dbo.UNITS AS U 
			WHERE id = COALESCE(@unit_id, id))
	BEGIN
		RAISERROR ('Еденица измерения %s не найдена!', 16, 1, @unit_id)
		RETURN -1
	END

	INSERT
	INTO dbo.PAYM_OCC_BUILD
	(	fin_id
		,occ
		,service_id
		,kol
		,tarif
		,Value
		,COMMENTS
		,unit_id
		,procedura)
		SELECT
			@fin_id1
			,O.occ
			,CL.service_id
			,COALESCE(@kol, 0)
			,COALESCE(@tarif, 0)
			,COALESCE(@value, 0)
			,@comments
			,@unit_id
			,'ka_opu_add' --'загрузка из файла'
		FROM dbo.OCCUPATIONS AS O -- для проверки что такой лицевой и услуга есть 
		JOIN dbo.CONSMODES_LIST AS CL 
			ON O.occ = CL.occ
		WHERE O.occ = @occ1
		AND CL.service_id = @service_id1
	SELECT
		@KolAdd = @@rowcount
go

