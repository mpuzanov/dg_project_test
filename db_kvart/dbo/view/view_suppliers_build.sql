-- dbo.view_suppliers_build source

CREATE   VIEW [dbo].[view_suppliers_build]
AS
SELECT
	b.fin_current AS fin_id
   ,sb.build_id AS build_id
   ,sb.sup_id
   ,sb.service_id
   ,sb.paym_blocked
   ,sb.add_blocked   
   ,sb.lastday_without_peny
   ,sb.is_peny
   ,sb.start_date_work
   ,sb.penalty_metod
   ,sb.print_blocked
   ,sb.gis_blocked
FROM dbo.SUPPLIERS_BUILD AS sb 
JOIN dbo.BUILDINGS b 
	ON sb.build_id = b.id
UNION ALL
SELECT
	sbh.fin_id
   ,sbh.build_id
   ,sbh.sup_id
   ,sbh.service_id
   ,sbh.paym_blocked
   ,sbh.add_blocked
   ,sbh.lastday_without_peny
   ,sbh.is_peny
   ,sbh.start_date_work
   ,sbh.penalty_metod
   ,sbh.print_blocked
   ,sbh.gis_blocked
FROM dbo.SUPPLIERS_BUILD_HISTORY AS sbh;
go

