CREATE   PROCEDURE [dbo].[rep_svod_jeu_all]
( @fin_id1 SMALLINT=NULL,    -- фин период
  @tip_id1 SMALLINT=NULL,    -- тип жилого фонда
  @div_id1 SMALLINT=NULL,    -- район
  @jeu1 SMALLINT=NULL,       -- участок
  @build1 INT=NULL,          -- дом
  @service_id1 VARCHAR(10)=NULL, -- услуга
  @mode_id1 INT =NULL,       -- режим
  @source_id1 INT =NULL,     -- поставщик  
  @town_id SMALLINT = NULL
) 
AS
/*
Пузанов
3.04.09

Отчет: jeusvod_all.fr3

*/

SET NOCOUNT ON


SELECT  
	jeu=b.sector_id, 
	sec.name as sec_name,
	serv_name=s.short_name, 
	mode_name=cm.name, 
	source_name=sup.name,
	s.service_no, 
	CurrentDate,
	CountLic=SUM(CountLic), 
	CountLicLgot=SUM(CountLicLgot), 
	CountLicSubsid=SUM(CountLicSubsid), 
	CountPeople=SUM(CountPeople), 
	CountPeoplelgot=SUM(CountPeoplelgot), 
	[SQUARE]=SUM(SQUARE),
	SquareLive=SUM(SquareLive)
FROM dbo.dom_svod_all AS ds 
     JOIN dbo.buildings AS b  ON ds.build_id=b.id
     JOIN dbo.cons_modes AS cm ON ds.mode_id=cm.id
     JOIN dbo.View_SERVICES AS s ON cm.service_id=s.id
     JOIN dbo.View_SUPPLIERS AS sup ON ds.source_id=sup.id
	 JOIN dbo.sector as sec ON b.sector_id=sec.id
WHERE ds.fin_id=COALESCE(@fin_id1,0)
     AND b.tip_id=COALESCE(@tip_id1,b.tip_id)
     AND b.div_id=COALESCE(@div_id1,b.div_id)
     AND b.sector_id=COALESCE(@jeu1,b.sector_id)
     AND b.id=COALESCE(@build1,b.id)     
     AND ds.mode_id=COALESCE(@mode_id1,ds.mode_id)
     AND ds.source_id=COALESCE(@source_id1,ds.source_id)
     AND cm.service_id=COALESCE(@service_id1,cm.service_id)   
     AND b.town_id=COALESCE(@town_id,b.town_id)          
GROUP BY b.sector_id, sec.name, s.short_name, cm.name, sup.name, s.service_no, CurrentDate

ORDER BY  jeu, service_no, CountLic DESC
go

