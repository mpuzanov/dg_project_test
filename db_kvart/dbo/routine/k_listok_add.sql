CREATE   PROCEDURE [dbo].[k_listok_add]
(
	@occ1			INT
	,@listok_id1	SMALLINT	= 1 -- тип листка 1-прибытия, 2-убытия
	,@id_new		INT			= 0 OUT
)
AS
	/*

Добавляем пустой листок прибытия или убытия
по заданному лицевому счету

*/
	SET NOCOUNT ON

	DECLARE	@err		INT
			,@id_tmp	INT

	SELECT TOP 1
		@id_tmp = pl.id
	FROM dbo.PEOPLE_LISTOK AS pl 
	WHERE occ = @occ1
	AND listok_id = @listok_id1
	AND (LTRIM(pl.Last_name) = '')

	IF @id_tmp IS NULL
	BEGIN
		DELETE FROM dbo.PEOPLE_LISTOK
		WHERE id = @id_tmp
	END

	DECLARE @DateCreate1 SMALLDATETIME
	SELECT
		@DateCreate1 = dbo.Fun_GetOnlyDate(current_timestamp)

	-- Добавляем
	INSERT
	INTO dbo.PEOPLE_LISTOK
	(	occ
		,listok_id
		,Last_name
		,First_name
		,Second_name
		,DateCreate)
	VALUES (@occ1, @listok_id1, '', '', '', @DateCreate1)
	
	SELECT
		@id_new = SCOPE_IDENTITY()
go

