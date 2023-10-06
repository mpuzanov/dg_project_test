-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_esplus_update] 
AS
/*
adm_esplus_update
*/
BEGIN
	SET NOCOUNT ON;
	
	-- поиск ПУ по адресу и серийному номеру
	UPDATE es
	SET counter_id=t1.id
		,service_id=t1.service_id
    FROM EsPlus_pu as es
		CROSS APPLY (
			SELECT TOP(1) c.id, c.flat_id, c.service_id
			FROM dbo.Counters AS c            
				JOIN dbo.Flats AS f 
					ON f.id = c.flat_id
				JOIN dbo.Buildings AS b 
					ON f.bldn_id = b.id
				JOIN dbo.VStreets AS s 
					ON b.street_id = s.id
			WHERE 1=1
			AND (                                    
				(s.name = es.street_name OR s.short_name = es.street_name) 
				AND (b.nom_dom = es.nom_dom) 
				AND (f.nom_kvr = es.nom_kvr) 
				AND (c.serial_number = es.serial_num)
				)	
		) as t1
			 
	update c 
	set external_id=es.id_lic_old
	from dbo.Counters as c 
		JOIN dbo.EsPlus_pu as es ON c.id=es.counter_id

	update cl 
	set lic_source=es.id_lic
	from dbo.consmodes_list as cl 
		join dbo.Occupations as o ON cl.occ=o.occ	
		join dbo.Counters as c ON c.flat_id=o.flat_id
		JOIN dbo.EsPlus_pu as es ON c.id=es.counter_id and cl.service_id=es.service_id	

END
go

