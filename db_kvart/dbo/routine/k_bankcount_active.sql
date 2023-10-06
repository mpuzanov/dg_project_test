CREATE   PROCEDURE [dbo].[k_bankcount_active]
(
	@id1 INT
)
AS
	/*
	--  Сделать активным банковский счет человека
	
	
	Пузанов
	25.08.2005
	*/

	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE @occ1		 INT
		   ,@owner_id1	 INT
		   ,@fin_current SMALLINT

	SELECT
		@occ1 = p.occ
	   ,@owner_id1 = bc.owner_id
	FROM dbo.PEOPLE AS p 
	JOIN dbo.BANK_COUNTS AS bc 
		ON p.id = bc.owner_id
	WHERE bc.id = @id1

	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с банковскими счетами запрещена', 16, 1)
		RETURN
	END

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	BEGIN TRAN

		UPDATE dbo.BANK_COUNTS 
		SET active = 0
		WHERE owner_id = @owner_id1
		AND active = 1


		UPDATE dbo.BANK_COUNTS
		SET active = 1
		WHERE id = @id1
		AND active = 0

		UPDATE dbo.COMPENSAC_ALL 
		SET transfer_bank = 1
		WHERE occ = @occ1
		AND fin_id = @fin_current

	COMMIT TRAN
go

