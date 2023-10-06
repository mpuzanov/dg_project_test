-- =============================================
-- Author:		Пузанов
-- Create date: 20.05.2014
-- Description:	Установка Ответственного лица на лицевом
-- =============================================
CREATE   PROCEDURE [dbo].[k_people_set_fam]
(
	@owner_id INT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @occ INT

	SELECT
		@occ = Occ
	FROM dbo.View_people
	WHERE id = @owner_id

	IF EXISTS (SELECT
				1
			FROM dbo.View_people
			WHERE Occ = @occ
			AND Fam_id = 'отвл'
			AND id <> @owner_id)
	BEGIN
		UPDATE dbo.PEOPLE 
		SET Fam_id = '????'
		WHERE Occ = @occ
		AND Fam_id = 'отвл'
		AND id <> @owner_id
	END


	UPDATE dbo.People 
	SET Fam_id = 'отвл'
	WHERE id = @owner_id

	
END
go

