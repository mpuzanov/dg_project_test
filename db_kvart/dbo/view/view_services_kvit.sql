-- dbo.view_services_kvit source

CREATE   VIEW [dbo].[view_services_kvit]
AS
	SELECT b.tip_id AS tip_id
		 , b.ID AS build_id
		 , s.ID AS service_id
		 , COALESCE(st.service_name, s.name) AS service_name
		 , COALESCE(sbuild.service_name_kvit_build, COALESCE(st2.service_name, COALESCE(st.service_name, s.name))) AS service_name_kvit
	FROM dbo.Buildings b
		CROSS JOIN dbo.Services s
		LEFT JOIN dbo.Services_types st 
			ON s.ID = st.service_id
			AND b.tip_id = st.tip_id
		LEFT JOIN dbo.Services_types st2 
			ON st.owner_id = st2.ID
		LEFT JOIN (
			SELECT st.build_id
				 , st.service_id
				 , st.service_name
				 , COALESCE(st2.service_name, st.service_name) AS service_name_kvit_build
			FROM dbo.Services_build st
				LEFT JOIN dbo.Services_build st2 
					ON st.owner_id = st2.ID
		) AS sbuild ON b.ID = sbuild.build_id
			AND s.ID = sbuild.service_id;
go

