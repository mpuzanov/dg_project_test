-- dbo.view_reports_favorites source

CREATE   VIEW [dbo].[view_reports_favorites]
AS
	SELECT rf.id
      ,rf.id_parent
      ,rf.user_id
      ,rf.rep_id
      ,rf.name
      ,rf.REPORT_BODY
      ,rf.rep_type
      ,rf.sql_query
      ,rf.date_edit
      ,rf.is_for_all
      ,dbo.fsize(rf.REPORT_BODY) AS size_body
	  ,us.Initials
  FROM dbo.Reports_favorites as rf
		LEFT JOIN dbo.Users AS us ON
			rf.user_id = us.id;
go

