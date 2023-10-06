CREATE   PROCEDURE [dbo].[adm_add_lgota]
(
	@lgota_new  SMALLINT
   ,@Lgota_name VARCHAR(30)
)
AS	
	--
	--  Добавляем льготу
	--
	SET NOCOUNT ON

	-- Проверяем есть ли такая льгота
	IF EXISTS (SELECT
				1
			FROM DSC_GROUPS
			WHERE id = @lgota_new)
	BEGIN
		RAISERROR ('Такая льгота уже есть!', 16, 10)
		RETURN 1
	END

	IF EXISTS (SELECT
				1
			FROM DSC_GROUPS
			WHERE name = @Lgota_name)
	BEGIN
		RAISERROR ('Льгота с таким названием уже есть!', 16, 10)
		RETURN 1
	END
	
	INSERT DSC_GROUPS
	(id
	,name)
	VALUES (@lgota_new
		   ,@Lgota_name)
go

