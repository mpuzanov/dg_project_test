-- =============================================
-- Author:		Пузанов
-- Create date: 19.11.2021
-- Description:	Изменение комментария у платежа
-- =============================================
CREATE       PROCEDURE [dbo].[k_paying_change_comment]
	  @paying_id INT -- код платежа
	, @comment_new VARCHAR(100) = NULL -- Новый текст комментария
	, @ZapUpdate INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	IF @comment_new IS NULL
		RETURN

	UPDATE p 
	SET p.comment = COALESCE(@comment_new, p.comment)
	FROM dbo.Payings p 
	WHERE p.id = @paying_id
	SELECT @ZapUpdate = @@rowcount

END
go

