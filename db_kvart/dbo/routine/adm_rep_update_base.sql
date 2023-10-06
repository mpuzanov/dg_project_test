-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[adm_rep_update_base]
(
	@db_name	VARCHAR(30) -- база, в которой надо обновить отчёты из текущей	
	,@debug		BIT			= 0
	,@KolUpdate	SMALLINT	= 0 OUTPUT -- кол-во обновлённых отчётов
)
AS
/*

adm_rep_update_base 'kvart',1

declare @KolUpdate	SMALLINT
exec adm_rep_update_base @db_name='kvart',@debug=0,@KolUpdate=@KolUpdate OUT
select @KolUpdate
*/
BEGIN

	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(4000)
	DECLARE @DB_NAME_CURRENT VARCHAR(20) = UPPER(DB_NAME())

	IF @db_name <> @DB_NAME_CURRENT
	BEGIN

		SET @SQL =
		'UPDATE r2 set r2.FileName=r.FileName, r2.REPORT_BODY=r.REPORT_BODY,r2.FileDateEdit=r.FileDateEdit ' + CHAR(13) +
		'FROM ' + @DB_NAME_CURRENT + '.dbo.REPORTS r JOIN ' + @db_name + '.dbo.REPORTS r2 ON r.Name=r2.Name ' + CHAR(13) +
		'WHERE (r.FileName<>'''') AND r.FileDateEdit>r2.FileDateEdit ' + CHAR(13) +
		'SET @KolUpdate=@@ROWCOUNT '

		IF @debug = 1
			PRINT @SQL
		ELSE
			EXECUTE master.sys.sp_executesql	@SQL
									,N'@KolUpdate smallint OUTPUT'
									,@KolUpdate = @KolUpdate OUTPUT
	END
	SELECT
		COALESCE(@KolUpdate,0)
/*							
SELECT r.FileName, r.FileDateEdit, r.Name, r2.FileName, r2.FileDateEdit, r2.Name
--UPDATE r2 set r2.REPORT_BODY=r.REPORT_BODY,r2.FileDateEdit=r.FileDateEdit
FROM dbo.REPORTS r 
JOIN kvart.dbo.REPORTS r2 ON r.Name=r2.Name
WHERE r.FileName<>'' AND r.FileDateEdit>r2.FileDateEdit
ORDER BY r.FileName
*/
END
go

