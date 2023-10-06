-- =============================================
-- Author:		Пузанов
-- Create date: 31.08.2015
-- Description:	Изменение наименования документа у перерасчёта
-- =============================================
CREATE     PROCEDURE [dbo].[ka_change_doc]
	  @id INT -- код разового
	, @doc_new VARCHAR(100) = NULL -- Новое наименование документа
	, @comment_new VARCHAR(100) = NULL -- Новый текст комментария
	, @ZapUpdate INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	IF @doc_new IS NULL
		AND @comment_new IS NULL
		RETURN

	UPDATE ap 
	SET ap.doc = COALESCE(@doc_new, ap.doc)
	  , ap.comments = COALESCE(@comment_new, ap.comments)
	FROM dbo.Added_Payments AS ap
	WHERE ap.id = @id
	SELECT @ZapUpdate = @@rowcount

END
go

