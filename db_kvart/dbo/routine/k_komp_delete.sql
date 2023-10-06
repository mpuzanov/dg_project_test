CREATE   PROCEDURE [dbo].[k_komp_delete]
(
	@occ1		INT
	,@deladd1	BIT	= 0
	, -- одновременно удалять разовые по субсидиям
	@ras1		BIT	= 1-- делать перерасчет квартплаты
)
AS
/*
Удаление субсидии по лицевому счету
*/
	SET NOCOUNT ON


	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Субсидиями запрещена', 16, 1)
		RETURN
	END

	IF (dbo.Fun_GetRejim() = 'чтен')
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE	@CurrentDate	SMALLDATETIME
			,@id1			INT
			,@fin_current	SMALLINT
	SELECT
		@CurrentDate = dbo.Fun_GetOnlyDate(current_timestamp)

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

BEGIN TRY

	DELETE FROM dbo.COMPENSAC_ALL 
	WHERE occ = @occ1 AND fin_id = @fin_current

	DELETE FROM dbo.COMP_SERV_ALL 
	WHERE occ = @occ1 AND fin_id = @fin_current

	COMMIT TRAN

	--************************
	-- удаляем разовые по субсидиям
	IF @deladd1 = 1
	BEGIN
		DELETE FROM dbo.ADDED_PAYMENTS 
		WHERE occ = @occ1 
			AND add_type = 4
	END
	--****************************************************************
	--UPDATE paym_list WITH(ROWLOCK)
	--SET compens=0
	--WHERE occ=@occ1


	-- Расчитываем квартплату
	IF @ras1 = 1
	BEGIN
		EXEC k_raschet_2	@occ1
							,@fin_current
	END

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'укмп'
	--****************************************

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

