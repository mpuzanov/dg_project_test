-- =============================================
-- Author:		Пузанов
-- Create date: 09.02.2010
-- Description:	Добавляем банковский счет по заданной организации
-- =============================================
CREATE     PROCEDURE [dbo].[adm_bank_account_add]
(
	@tip1			SMALLINT -- 1 - Тип жил.фонда, 2 - Участок, 3 - Поставщик, 4 - Район, 5 - Дом, 6 - Договор, 7 - Лицевой
	,@name_str1		VARCHAR(100)	= ''
	,@bank			VARCHAR(50)		= ''
	,@rasschet		VARCHAR(20)		= '0'
	,@korschet		VARCHAR(20)		= '0'
	,@bik			VARCHAR(9)		= '0'
	,@inn			VARCHAR(12)		= '0'
	,@licbank		BIGINT			= 0
	,@id_barcode	VARCHAR(50)		= ''
	,@comments		VARCHAR(50)		= ''
	,@id			INT				= 0 OUTPUT
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

	SET @id = 0

	SELECT
		@org_name_str1 = name
	FROM dbo.ACCOUNT_ORG
	WHERE rasschet = @rasschet
	AND bik = @bik
	AND licbank = @licbank
	AND id_barcode = @id_barcode

	IF @org_name_str1 IS NOT NULL
	BEGIN
		SET @msg = 'Ошибка создания банковского счета!' + CHAR(13) + 'Такие: Расчетный счет, БИК, Лиц.Банка, Код орг. уже есть!' + CHAR(13) + 'У получателя: ' + @org_name_str1
		RAISERROR (@msg, 16, 1);
		RETURN 1
	END

	INSERT
	INTO [dbo].[ACCOUNT_ORG]
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
	VALUES (@rasschet
			,@bik
			,@licbank
			,@name_str1
			,@bank
			,@korschet
			,@inn
			,@id_barcode
			,@comments
			,@tip1
			,@name_str2
			,@barcode_type
			,@kpp
			,@cbc
			,@oktmo)

	-- Получаем код банковского счета
	SELECT
		@id = SCOPE_IDENTITY()

END
go

