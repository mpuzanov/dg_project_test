-- dbo.vocc_types_access source

CREATE   VIEW [dbo].[vocc_types_access]
AS  -- для ограничения доступа
	SELECT o.id
		 , o.name
		 , o.payms_value
		 , o.fin_id
		 , o.start_date
		 , o.state_id
		 , o.raschet_no
		 , o.PaymClosed
		 , o.ras_paym_fin_new
	FROM dbo.Occupation_Types AS o
		INNER JOIN (
			SELECT su.SYSUSER
				 , uot.ONLY_TIP_ID
				 , CAST(uot.only_read AS BIT) AS only_read
				 , uot.fin_id_start
			FROM (SELECT system_user AS SYSUSER) AS su
				LEFT OUTER JOIN dbo.Users_occ_types AS uot ON 
					su.SYSUSER = uot.SYSUSER
		) AS uo ON 
		(uo.ONLY_TIP_ID IS NULL OR o.id = uo.ONLY_TIP_ID);
go

