-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE               PROCEDURE [dbo].[rep_favorites_show]
(
	  @user_id1 SMALLINT = NULL
)
/*
exec rep_favorites_show 2
*/
AS
BEGIN
	SET NOCOUNT ON;

	SELECT rf.id
		 , rf.id_parent
		 , rf.user_id
		 , rf.rep_id
		 , CAST(CASE
			   WHEN COALESCE(rf.name, '') <> '' THEN rf.name
			   WHEN r.Level1 IS NOT NULL THEN concat(LTRIM(STR(r.Level1)) , '.' , LTRIM(STR(r.Level2)) , '. ' , r.name)
			   WHEN ro.id IS NOT NULL THEN ro.name
			   ELSE '?'
		   END AS VARCHAR(100))           AS FullName
		 , rf.name
		 , CASE
               WHEN r.FileName IS NOT NULL THEN r.FileName
               ELSE ro.FileName
        END                               AS FileName
		 , CAST(CASE
                    WHEN rep_id IS NULL AND rf.REPORT_BODY IS NULL THEN 1
                    ELSE 0
        END AS BIT)                       AS is_group
		 --, rf.REPORT_BODY AS REPORT_BODY_favor -- перенёс получение в клиента
		 , cast(NULL as varbinary(MAX))   AS REPORT_BODY_favor
		 , rf.rep_type
		 , rf.sql_query
	     , rf.is_for_all
		 --, dbo.Fun_GetFIOUser(rf.user_id) AS username
		 , rf.Initials AS username
		 , case 
			when rf.rep_type='OLAP' then rf.size_body
			when rf.rep_type='REPORTS' AND rf.rep_id = r.id then r.SIZE_REPORT_BODY			 
		 end as size_body
	FROM dbo.View_reports_favorites rf 
		LEFT JOIN dbo.Reports AS r 
			ON rf.rep_id = r.id AND rf.rep_type='REPORTS'
		LEFT JOIN dbo.Reports_olap ro 
			ON rf.rep_id = ro.id AND rf.rep_type='OLAP'
	WHERE (rf.user_id = @user_id1
	    or rf.is_for_all = 1 or SYSTEM_USER='sa')
		and rf.rep_type in ('REPORTS', 'OLAP', 'GROUP')
	ORDER BY rf.name
		   , r.Level1
		   , r.Level2
END
go

