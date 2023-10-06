CREATE   PROCEDURE [dbo].[adm_addsuppliers_serv]
(
	@service_id1 VARCHAR(10)
   ,@name1		 VARCHAR(50)
)
AS

	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM dbo.SUPPLIERS
			WHERE service_id = @service_id1
			AND Name = @name1)
	BEGIN
		RAISERROR ('Такой поставщик уже есть', 16, 1)
		RETURN 1
	END

	DECLARE @service_no1 SMALLINT
		   ,@sup_id		 INT

	SELECT
		@sup_id = Id
	FROM dbo.SUPPLIERS_ALL
	WHERE Name = @name1

	SELECT
		@service_no1 = service_no
	FROM dbo.SERVICES AS s
	WHERE s.Id = @service_id1

	DECLARE @kod INT
	SELECT
		@kod = MAX(Id) + 1
	FROM dbo.SUPPLIERS
	WHERE service_id = @service_id1

	IF @kod IS NULL
		SET @kod = @service_no1 * 1000

	SELECT
		@kod
	   ,@service_id1
	   ,@sup_id

	SELECT
		*
	FROM dbo.SUPPLIERS
	WHERE service_id = @service_id1

	INSERT INTO dbo.SUPPLIERS
	(Id
	,service_id
	,sup_id)
	VALUES (@kod
		   ,@service_id1
		   ,@sup_id)

	SELECT
		*
	FROM dbo.SUPPLIERS
	WHERE service_id = @service_id1
go

