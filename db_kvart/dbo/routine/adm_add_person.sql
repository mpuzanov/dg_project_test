CREATE   PROCEDURE [dbo].[adm_add_person]
(
	@id_copy VARCHAR(10) = NULL -- статус регистрации с которого надо создать дубль
)
AS
	/*
		Добавить новый статус прописки
	*/
	SET NOCOUNT ON

	DECLARE @Id1 VARCHAR(10)
		   ,@Kod SMALLINT

	SELECT
		@Kod = 1000 + COUNT(id)
	FROM dbo.Person_statuses
	SET @Id1 = LTRIM(STR(@Kod))

	IF NOT EXISTS (SELECT
				1
			FROM dbo.PERSON_STATUSES
			WHERE id = @Id1)
	BEGIN
		INSERT INTO dbo.Person_statuses
		(id
		,name
		,short_name)
		VALUES (@Id1
			   ,'Новый статус ?'
			   ,'????')
	END

	-- Берём услуги со статуса на входе
	IF @id_copy IS NOT NULL
		INSERT INTO [dbo].[PERSON_CALC]
		(status_id
		,service_id
		,have_paym
		,is_rates)
			SELECT
				@Id1
			   ,[service_id]
			   ,[have_paym]
			   ,[is_rates]
			FROM [dbo].[PERSON_CALC]
			WHERE status_id = @id_copy
go

