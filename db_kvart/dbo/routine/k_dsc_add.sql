CREATE   PROCEDURE [dbo].[k_dsc_add]
/*
  Добавляем льготу
*/
(
	@owner_id1		INT	
	,@dscgroup_id1	SMALLINT  -- номер льготы
	,@doc1			VARCHAR(50)
	,@issued1		DATETIME
	,@issued2		DATETIME
	,@expire_date1	DATETIME	= '20500101'
	,@doc_no1		VARCHAR(10)	= NULL
	,@doc_seria1	VARCHAR(10)	= NULL
	,@doc_org1		VARCHAR(30)	= NULL
)
AS
	SET NOCOUNT ON

	IF @dscgroup_id1 = 0
	BEGIN
		RETURN 0
	END

	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	IF EXISTS (SELECT
				*
			FROM dbo.Dsc_owners AS ow
			JOIN dbo.Fun_SpisokLgotaActive(@owner_id1) AS ow2
				ON ow.id = ow2.id1
			WHERE ow.owner_id = @owner_id1
			AND ow.dscgroup_id = @dscgroup_id1)
	BEGIN
		RAISERROR (N'Такая льгота уже есть!', 16, 1)
	END

	DECLARE @id1 INT
			,@user_id1 SMALLINT			

	SELECT
		@user_id1 = id
	FROM dbo.USERS 
	WHERE login = system_user

	BEGIN TRAN

		-- Добавляем
		INSERT INTO dbo.DSC_OWNERS
		(	owner_id
			,dscgroup_id
			,active
			,doc
			,issued
			,issued2
			,expire_date
			,user_id
			,doc_no
			,doc_seria
			,doc_org)
		VALUES (@owner_id1
				,@dscgroup_id1
				,0
				,@doc1
				,@issued1
				,@issued2
				,@expire_date1
				,@user_id1
				,@doc_no1
				,@doc_seria1
				,@doc_org1)

		SELECT
			@id1 = SCOPE_IDENTITY()

		EXEC dbo.k_dsc_active @id1

	COMMIT TRAN
go

