CREATE   PROCEDURE [dbo].[adm_del_doctype]
(
	@doc_id1 VARCHAR(10)
)
AS

	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1
			FROM IDDOC
			WHERE doctype_id = @doc_id1)
	BEGIN
		DELETE FROM IDDOC_TYPES
		WHERE id = @doc_id1
	END
	ELSE
		RAISERROR ('Этот тип документа используется! Его удалить нельзя!', 16, 10)
go

