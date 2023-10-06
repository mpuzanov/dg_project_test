-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_rep_add]
	@name				VARCHAR(100)
	,@FileName			VARCHAR(100)	= NULL
	,@APP				VARCHAR(15)		= 'DREP'
	,@ID_PARENT			SMALLINT		= NULL
	,@report_body		VARBINARY(MAX)	= NULL
	,@FileDateEdit		SMALLDATETIME	= NULL
	,@Personal_access	BIT				= NULL
	,@Procedures		VARCHAR(50)		= NULL
	,@ID				INT				OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@level1		SMALLINT
			,@level2	SMALLINT

	IF @APP IS NULL
		SET @APP = 'DREP'

	IF @ID_PARENT IS NULL
	BEGIN
		SELECT
			@level1 = MAX(Level1)
		FROM dbo.REPORTS AS R

		SELECT
			@ID_PARENT = 0
	END
	ELSE
		SELECT
			@level1 = Level1
		FROM dbo.REPORTS AS R
		WHERE id = @ID_PARENT

	SELECT
		@level2 = MAX(Level2)
	FROM dbo.REPORTS AS R
	WHERE Level1 = @level1

	SELECT
		@level2 = COALESCE(@level2, 0) + 1

	INSERT INTO dbo.REPORTS
	(	Level1
		,Level2
		,Name
		,[FileName]
		,APP
		,ID_PARENT
		,REPORT_BODY
		,FileDateEdit
		,Personal_access
		,Procedures)
			SELECT
				@level1
				,@level2
				,@name
				,@FileName
				,@APP
				,@ID_PARENT
				,@report_body
				,@FileDateEdit
				,@Personal_access
				,@Procedures

	SELECT
		@ID = SCOPE_IDENTITY()

END
go

