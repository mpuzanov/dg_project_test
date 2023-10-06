CREATE   PROCEDURE [dbo].[adm_add_doctype]
(
	  @doc_id1 VARCHAR(10)
)
AS
	SET NOCOUNT ON

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Iddoc_types
			WHERE id = @doc_id1
		)
	BEGIN
		INSERT dbo.Iddoc_types
			(id
		   , name
		   , short_name)
			VALUES (@doc_id1
				  , 'названия нет'
				  , '')
	END
	ELSE
		RAISERROR ('Такой тип документа <%s> уже есть!', 16, 10, @doc_id1)
go

