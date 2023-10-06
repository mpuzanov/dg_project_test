CREATE   TRIGGER [dbo].[COMPENSAC_ALL_READONLY]
ON [dbo].[Compensac_all]
FOR INSERT, UPDATE, DELETE
AS

	SET NOCOUNT ON

	DECLARE @user_id1 SMALLINT
	SELECT
		@user_id1 = id
	FROM dbo.USERS
	WHERE login = system_user

	IF EXISTS (SELECT
				1
			FROM dbo.GROUP_MEMBERSHIP
			WHERE group_id = 'оптч'
			AND user_id = @user_id1)
	BEGIN
		ROLLBACK TRAN
	-- RAISERROR('У Вас доступ только для чтения',16,10)
	END

	DECLARE @SubClosedDate1 SMALLDATETIME
	SELECT
		@SubClosedDate1 = SubClosedData
	FROM dbo.GLOBAL_VALUES
	WHERE closed = 0
	IF @SubClosedDate1 IS NOT NULL
	BEGIN
		ROLLBACK TRAN
		RAISERROR ('Доступ к субсидии сейчас запрещен!', 16, 10)
	END
go

disable trigger COMPENSAC_ALL_READONLY on Compensac_all
go

