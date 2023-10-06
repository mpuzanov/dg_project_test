CREATE   PROCEDURE [dbo].[k_people_delete_cancel]
(
	  @owner_id1 INT
)
AS
	-- Отмена выписки человека в текущем месяце

	SET NOCOUNT ON;

	DECLARE @occ1 INT
		  , @err INT

	DECLARE @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @DateDel SMALLDATETIME
		  , @Initials VARCHAR(30)
		  , @fin_current SMALLINT
		  , @fin_pred SMALLINT
		  , @end_date_pred SMALLDATETIME  -- дата окончания пред.периода

	SELECT @occ1 = Occ
		 , @DateDel = DateDel
		 , @Initials = CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.')
	FROM dbo.People 
	WHERE id = @owner_id1

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END
	IF NOT EXISTS(SELECT 1 FROM dbo.AccessAddPeople)
	BEGIN
		RAISERROR ('У вас нет прав прописки-выписки граждан', 16, 1)
		RETURN
	END

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
	SELECT @fin_pred = @fin_current - 1

	SELECT @start_date = start_date
		 , @end_date_pred = DATEADD(MINUTE, -1, start_date)
	FROM dbo.Global_values
	WHERE fin_id = @fin_current

	-- проверяем был ли он зарегистрирован полный предыдущий период
	-- возможно его по ошибке удалили в тек. периоде
	IF (@DateDel < @start_date)
		AND EXISTS (
			SELECT 1
			FROM People_history ph
			WHERE ph.fin_id = @fin_pred
				AND Occ = @occ1
				AND ph.owner_id = @owner_id1
				AND ph.data2 < @end_date_pred
		)
	BEGIN
		RAISERROR ('Нельзя восстановить человека! Так как Дата выписки не в текущем месяце', 16, 1)
		RETURN 1
	END

	--- Начинаем транзакцию
	BEGIN TRAN

		UPDATE dbo.People
		SET Del = 0
		  , DateDel = NULL
		  , Reason_extract = NULL
		WHERE id = @owner_id1
	
	COMMIT TRAN

	EXEC k_occ_status @occ1
go

