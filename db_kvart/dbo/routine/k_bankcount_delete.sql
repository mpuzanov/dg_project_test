CREATE   PROCEDURE [dbo].[k_bankcount_delete]
(
	@id1 INT
)
AS
	/*
	--
	-- Удаляем банковский счет человека
	
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
		   ,@fin_current SMALLINT

	SELECT
		@occ1 = occ
	FROM dbo.PEOPLE AS p
		,dbo.BANK_COUNTS AS bc 
	WHERE bc.id = @id1
	AND p.id = bc.owner_id

	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с банковскими счетами запрещена', 16, 1)
		RETURN
	END

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	-- Если удаляемый счет активный
	-- то надо найти нового активного если есть
	IF EXISTS (SELECT
				1
			FROM BANK_COUNTS 
			WHERE id = @id1
			AND active = 1)
	BEGIN
		DECLARE @owner_id1 INT
		SELECT
			@owner_id1 = owner_id
		FROM BANK_COUNTS 
		WHERE id = @id1

		UPDATE dbo.COMPENSAC_ALL 
		SET transfer_bank = 0
		WHERE occ = @occ1
		AND fin_id = @fin_current

		DELETE FROM dbo.BANK_COUNTS 
		WHERE id = @id1

		UPDATE dbo.BANK_COUNTS 
		SET active = 1
		WHERE id = (SELECT TOP 1
				id
			FROM dbo.BANK_COUNTS 
			WHERE owner_id = @owner_id1
			ORDER BY data_open DESC)
	END
	ELSE
	BEGIN
		DELETE FROM dbo.BANK_COUNTS 
		WHERE id = @id1
	END
go

