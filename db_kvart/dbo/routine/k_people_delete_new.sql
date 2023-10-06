CREATE   PROCEDURE [dbo].[k_people_delete_new]
(
	  @owner_id1 INT
)
AS
	-- Удаляем случайно введенного человека человека

	SET NOCOUNT ON
	SET XACT_ABORT ON;

	DECLARE @occ1 INT
		  , @msg VARCHAR(50)
		  , @Initials_people VARCHAR(30)

	SELECT @occ1 = occ
		 , @Initials_people = CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.')
	FROM dbo.People 
	WHERE id = @owner_id1

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.People_history
			WHERE occ = @occ1
				AND owner_id = @owner_id1
		)
	BEGIN -- его нет в истории
		DELETE FROM dbo.People
		WHERE id = @owner_id1

		IF @Initials_people <> ''
		BEGIN
			SET @msg = 'Удаляем случайно введенного гражданина (' + @Initials_people + ')'
			EXEC k_write_log @occ1
						   , 'удчл'
						   , @msg
		END
		EXEC k_occ_status @occ1
	END
go

