-- dbo.view_services_access source

CREATE   VIEW [dbo].[view_services_access]
AS
SELECT
	s.id
	,s.name
	,s.short_name
	,s.service_no
	,s.is_peny
	,s.is_build
FROM dbo.Services AS s
INNER JOIN (SELECT
		su.SYSUSER
		,us.ONLY_SERVICE_ID
	FROM (SELECT
			SUSER_SNAME() AS SYSUSER) AS su
	LEFT OUTER JOIN (SELECT
			p1.sysuser
			,p2.ONLY_SERVICE_ID
		FROM dbo.Group_members AS p1
		INNER JOIN dbo.Group_services AS p2
			ON p1.group_id = p2.group_id) AS us
		ON su.SYSUSER = us.sysuser) AS uo
	ON s.id = COALESCE(uo.ONLY_SERVICE_ID, s.id);
go

