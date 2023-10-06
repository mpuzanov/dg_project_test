CREATE   TRIGGER [dbo].[trDSC_OWNERS_READONLY]
ON [dbo].[Dsc_owners]
FOR INSERT, UPDATE, DELETE
AS
	SET NOCOUNT ON
	
	DECLARE @user_id1 SMALLINT
	SELECT
		@user_id1 = id
	FROM dbo.Users 
	WHERE login = system_user

	IF EXISTS (SELECT
				1
			FROM dbo.Group_membership
			WHERE group_id = 'оптч'
			AND user_id = @user_id1)
	BEGIN
		ROLLBACK TRAN
	-- RAISERROR('У Вас доступ только для чтения',16,10)
	END

	--DECLARE @occ1 INT
	--SELECT TOP 1
	--	@occ1 = p.occ
	--FROM	DELETED AS I
	--		JOIN dbo.PEOPLE AS p ON I.owner_id = p.id
	
	-- сохраняем в историю изменений
	--EXEC k_write_log	@occ1
	--					,'рдлг'
go

