-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[rep_favorites_add]
(
	  @user_id1 SMALLINT
	, @rep_id1 INT = NULL
	, @name1 VARCHAR(100) = NULL
	, @REPORT_BODY VARBINARY(MAX) = NULL
	, @rep_types VARCHAR(10) = 'REPORTS'
	, @sql_query varchar(8000) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @rep_id1 IS NULL
		AND COALESCE(@name1, '') = ''
		RETURN

	IF @rep_types IS NULL
		SET @rep_types = 'REPORTS'

	IF NOT EXISTS (
			SELECT *
			FROM dbo.Reports_favorites rf
			WHERE rf.user_id = @user_id1
				AND (
				--(rf.rep_id = COALESCE(@rep_id1,0)) OR 
				(rf.name = @name1)
				)
		)
		INSERT dbo.Reports_favorites (user_id
									, rep_id
									, [name]
									, REPORT_BODY
									, rep_type
									, sql_query)
		VALUES(@user_id1
			 , @rep_id1
			 , @name1
			 , @REPORT_BODY
			 , @rep_types
			 , @sql_query)
	ELSE
	IF @REPORT_BODY IS NOT NULL
		AND @name1 IS NOT NULL
		UPDATE dbo.Reports_favorites
		SET REPORT_BODY = @REPORT_BODY
		WHERE [name] = @name1

END
go

