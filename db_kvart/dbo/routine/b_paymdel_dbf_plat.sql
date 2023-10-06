CREATE   PROCEDURE [dbo].[b_paymdel_dbf_plat]
(
	@id INT
)
AS
	--
	--  удаляем лицевой из заданного файла
	--
	SET NOCOUNT ON


	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF
			WHERE (id = @id)
			AND (pack_id IS NOT NULL))
	BEGIN
		RAISERROR ('Удалить нельзя! сформированы пачки из этих платежей!', 16, 1)
		RETURN 1
	END

	DECLARE @user_id1  SMALLINT
			,@date1	   SMALLDATETIME
			,@id1	   INT
			,@sch_lic1  BIGINT
			,@occ2	   INT
			,@adres1	   VARCHAR(50)
			,@adres2	   VARCHAR(50)
			,@comments1 VARCHAR(50)
			,@sum_plat  DECIMAL(9, 2)

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()

BEGIN TRAN

	SELECT
		@id1 = id
		,@sch_lic1 = sch_lic
		,@sum_plat = sum_opl
		,@occ2 = COALESCE(occ, 0)
		,@adres1 = adres
		,@adres2 = adres
	FROM dbo.BANK_DBF
	WHERE id = @id
		
	SELECT
		@comments1 = 'платеж удален с суммой: ' + CONVERT(VARCHAR(10), @sum_plat)

	INSERT INTO dbo.BANK_DBF_LOG
	(user_id
	,dateEdit
	,kod_paym
	,occ1
	,adres1
	,occ2
	,adres2
	,comments)
	VALUES (@user_id1
			,@date1
			,@id1
			,@sch_lic1
			,@adres1
			,@occ2
			,@adres2
			,@comments1)

	DELETE FROM dbo.BANK_DBF
	WHERE (id = @id)
		AND (pack_id IS NULL) --AND


COMMIT TRAN
go

