CREATE   PROCEDURE [dbo].[adm_change_schtl]
(
	@occ1	   INT
   ,@schtl_new INT
   ,@Result	   BIT OUTPUT
)
AS
	--
	-- Процедура смены старых лицевых счетов
	--

	SET NOCOUNT ON

	SET @Result = 0

	DECLARE @user_id1  SMALLINT
		   ,@msg	   VARCHAR(100)
		   ,@schtl_old INT
		   ,@jeu1	   SMALLINT

	SELECT
		@schtl_old = COALESCE(SCHTL, 0)
	   ,@jeu1 = JEU
	FROM dbo.OCCUPATIONS AS o 
	WHERE occ = @occ1


	SET @msg = concat(' Изменения не сделаны! Участок: ' , @jeu1, ' и Лицевой: ' , @schtl_new , ' уже есть')

	IF EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE JEU = @jeu1
			AND SCHTL = @schtl_new)
	BEGIN
		SET @msg = @msg + 'OCCUPATIONS'
		RAISERROR (@msg, 11, 1)
		RETURN 1
	END

	BEGIN TRAN

		UPDATE dbo.OCCUPATIONS WITH (ROWLOCK)
		SET SCHTL = @schtl_new
		WHERE occ = @occ1

		SELECT	@user_id1 = id	FROM USERS	WHERE login = system_user

		INSERT INTO IZMLIC
		(datizm
		,jeu1
		,schtl1
		,jeu2
		,schtl2
		,user_id)
		VALUES (current_timestamp
			   ,@jeu1
			   ,@schtl_old
			   ,@jeu1
			   ,@schtl_new
			   ,@user_id1)

		SET @Result = 1 -- Изменения успешно сделаны

	COMMIT TRAN
go

