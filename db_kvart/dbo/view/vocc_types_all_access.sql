-- dbo.vocc_types_all_access source

CREATE   VIEW [dbo].[vocc_types_all_access]
AS	-- для ограничения доступа
	SELECT o.fin_id
		 , o.start_date
		 , o.id
		 , o.name
		 , o.payms_value
	FROM (
		SELECT fin_id
			 , start_date
			 , id
			 , name
			 , payms_value
		FROM dbo.Occupation_Types_History AS o2
		UNION
		SELECT fin_id
			 , start_date
			 , id
			 , name
			 , payms_value
		FROM dbo.Occupation_Types AS o1
	) AS o
		INNER JOIN (
			SELECT su.SYSUSER
				 , uot.ONLY_TIP_ID
				 , COALESCE(uot.fin_id_start, 71) AS fin_id_start
			FROM (SELECT SUSER_SNAME() AS SYSUSER) AS su
				LEFT OUTER JOIN dbo.Users_occ_types AS uot ON su.SYSUSER = uot.SYSUSER
		) AS uo ON o.id = COALESCE(uo.ONLY_TIP_ID, o.id)
			AND system_user = uo.SYSUSER
			AND o.fin_id > uo.fin_id_start;
go

