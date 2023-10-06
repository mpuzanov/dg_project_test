CREATE   PROCEDURE [dbo].[ka_show_types_add]
AS
	--
	--  Выводим список типов разовых
	-- ka_show_types_add
	--
	SET NOCOUNT ON

	SELECT
		id
		,name
	FROM dbo.ADDED_TYPES
	WHERE visible = 1
	ORDER BY type_no
go

