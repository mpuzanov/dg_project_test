-- =============================================
-- Author:		Пузанов
-- Create date: 16.02.2012
-- Description:	Копируем банковский счет
-- =============================================
CREATE     PROCEDURE [dbo].[adm_bank_account_copy]
(
	@id			INT
	,@id_new	INT	OUTPUT
)
AS
/*


*/
BEGIN
	SET NOCOUNT ON;

	INSERT INTO [dbo].[ACCOUNT_ORG]
	(	[rasschet]
		,[bik]
		,[licbank]
		,[name_str1]
		,[bank]
		,[korschet]
		,[inn]
		,[id_barcode]
		,[comments]
		,[tip]
		,[name_str2]
		,barcode_type
		,kpp
		,cbc
		,oktmo)
			SELECT
				'00000000000000000000' AS rasschet
				,bik
				,(licbank + 1)
				,name_str1
				,bank
				,korschet
				,inn
				,0
				,comments
				,tip
				,name_str2
				,barcode_type
				,kpp
				,cbc
				,oktmo
			FROM dbo.ACCOUNT_ORG
			WHERE id = @id

	-- Получаем новый код банковского счета
	SELECT
		@id_new = SCOPE_IDENTITY()

END
go

