CREATE   PROCEDURE [dbo].[k_update_address_new]
(
	@occ1		INT
	,@flat_new	INT-- код новой квартиры
)
AS
	--
	--  изменяем старый адрес  лицевого счета на новый
	--
	SET NOCOUNT ON
	SET XACT_ABORT ON;

	IF dbo.Fun_AccessDelLic(@occ1) = 0
	BEGIN
		RAISERROR ('Вам запрещено изменять адрес', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE	@build_id_new	INT -- новый код дома
			,@flat_id_old	INT -- код старой квартиры
	SELECT
		@build_id_new = bldn_id
	FROM dbo.FLATS AS F 
	WHERE F.id = @flat_new

	SELECT
		@flat_id_old = O.flat_id
	FROM dbo.OCCUPATIONS O 
	WHERE occ = @occ1

	UPDATE O 
	SET	flat_id		= @flat_new
		,[address]	= [dbo].[Fun_GetAdres](b.id, @flat_new, O.occ)
	FROM dbo.OCCUPATIONS O
	JOIN dbo.FLATS AS f 
		ON O.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	WHERE occ = @occ1

	-- Меняем в истории
	UPDATE Oh 
	SET	flat_id		= @flat_new
	FROM dbo.OCC_HISTORY AS Oh
	WHERE Oh.occ = @occ1
	
	-- Меняем адрес счётчиков по этому лицевому
	UPDATE C
	SET	flat_id		= @flat_new
		,build_id	= @build_id_new
	FROM dbo.COUNTER_LIST_ALL AS CL
	JOIN dbo.COUNTERS AS C
		ON CL.counter_id = C.id
	WHERE CL.occ = @occ1
	AND C.flat_id = @flat_id_old
go

