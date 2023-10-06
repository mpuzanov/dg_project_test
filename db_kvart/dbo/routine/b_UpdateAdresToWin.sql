-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Сменить кодировку Текстовых полей из OEM to WIN
-- =============================================
CREATE   PROCEDURE [dbo].[b_UpdateAdresToWin]
(
	@filedbf_id INT
)
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE b 
	SET	ADRES	= dbo.Fun_DOStoWIN(ADRES)
	FROM dbo.BANK_DBF AS b
	WHERE b.filedbf_id = @filedbf_id
END
go

