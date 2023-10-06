-- =============================================
-- Author:		Пузанов
-- Create date: 12.02.2010
-- Description:	Изменяем банковский счет по заданной организации
-- =============================================
CREATE   PROCEDURE [dbo].[adm_bank_account_edit]
(
	@id1			INT
	,@name_str1		VARCHAR(100)	= ''
	,@bank			VARCHAR(50)		= ''
	,@rasschet		VARCHAR(20)		= '0'
	,@korschet		VARCHAR(20)		= '0'
	,@bik			VARCHAR(9)		= '0'
	,@inn			VARCHAR(12)		= '0'
	,@licbank		BIGINT			= 0
	,@id_barcode	VARCHAR(50)		= ''
	,@comments		VARCHAR(50)		= ''
	,@name_str2		VARCHAR(100)	= ''
	,@barcode_type	SMALLINT		= 1
	,@kpp			VARCHAR(9)		= '0'
	,@cbc			VARCHAR(20)		= ''
	,@oktmo			VARCHAR(11)		= ''
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@msg			VARCHAR(800)
			,@org_name_str1	VARCHAR(50)

	IF @licbank IS NULL
		SET @licbank = 0
	IF @id_barcode IS NULL
		SET @id_barcode = 0

	SELECT
		@org_name_str1 = name
	FROM dbo.ACCOUNT_ORG
	WHERE rasschet = @rasschet
	AND bik = @bik
	AND licbank = @licbank
	AND id_barcode = @id_barcode
	AND id <> @id1

	IF @org_name_str1 IS NOT NULL
	BEGIN
		SET @msg = 'Ошибка создания банковского счета!' + CHAR(13) + 'Такие: Расчетный счет, БИК, Лиц.Банка, Код орг. уже есть' + CHAR(13) + 'У получателя: ' + @org_name_str1
		RAISERROR (@msg, 16, 1);
		RETURN 1
	END

	UPDATE [dbo].[ACCOUNT_ORG]
	SET	[rasschet]		= @rasschet
		,[bik]			= @bik
		,[licbank]		= @licbank
		,[name_str1]	= @name_str1
		,[bank]			= @bank
		,[korschet]		= @korschet
		,[inn]			= @inn
		,[id_barcode]	= @id_barcode
		,[comments]		= @comments
		,[name_str2]	= @name_str2
		,barcode_type	= @barcode_type
		,kpp			= @kpp
		,cbc			= @cbc
		,oktmo			= @oktmo
	WHERE id = @id1

END
go

