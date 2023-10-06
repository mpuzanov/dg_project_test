-- =============================================
-- Author:		Пузанов
-- Create date: 17.03.2010
-- Description:	История работы пользователей
-- =============================================
CREATE     PROCEDURE [dbo].[rep_users_work]
	@data1		SMALLDATETIME	= NULL
	,@data2		SMALLDATETIME	= NULL
	,@user1		SMALLINT		= NULL
	,@op_id1	VARCHAR(10)		= NULL
AS
BEGIN
	SET NOCOUNT ON;


	DECLARE @d DATETIME
	SET @d = CONVERT(CHAR(8), current_timestamp, 112)

	IF @data1 IS NULL
		SELECT
			@data1 = DATEADD(DAY, 1 - DAY(@d), @d) -- первый день месяца
	IF @data2 IS NULL
		SET @data2 = @d;

	SELECT
		u.Initials
		,COALESCE(comp, '-') AS comp
		,o.Name
		,COUNT([occ]) AS kol
	FROM [dbo].[OP_LOG] AS oplog 
	JOIN dbo.USERS AS u 
		ON oplog.user_id = u.id
	JOIN dbo.OPERATIONS AS o
		ON oplog.op_id = o.op_id
	WHERE done BETWEEN @data1 AND @data2
	AND u.id = COALESCE(@user1, u.id)
	AND o.op_id = COALESCE(@op_id1, o.op_id)
	GROUP BY	u.Initials
				,comp
				,o.Name
	ORDER BY u.Initials

END
go

