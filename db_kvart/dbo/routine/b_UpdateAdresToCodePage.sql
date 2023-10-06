-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Сменить кодировку Текстовых полей из (DOS->WIN или WIN->DOS )
-- =============================================
CREATE     PROCEDURE [dbo].[b_UpdateAdresToCodePage]
(
	@filedbf_id INT
	,@setCodePage VARCHAR(10) = 'WIN' --'DOS'
)
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE b 
	SET	ADRES	= dbo.Fun_ChangeCodePageStr(adres,@setCodePage)
	FROM dbo.BANK_DBF AS b
	WHERE b.filedbf_id = @filedbf_id
END
go

