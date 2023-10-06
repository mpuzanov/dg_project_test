CREATE   PROCEDURE [dbo].[rep_dogovor] 
( 
   @fin_id SMALLINT,  -- Фин.период
   @tip SMALLINT = NULL,      -- тип жилого фонда
   @sup_id INT = NULL --Поствщик
)
AS
/*
--

-- дата изменения:	
-- автор изменения:	Пузанов

отчет: 

rep_dogovor 195

*/
SET NOCOUNT ON


DECLARE @Fin_current SMALLINT

-- находим значение текущего фин периода  
IF @fin_id IS NULL SET @fin_id=dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

SELECT 
	dog.dog_id
	, b.street_name
	, b.nom_dom
	, o.nom_kvr
	, o.nom_kvr_sort
	, p.*
FROM dbo.View_DOG_ALL as dog
  JOIN dbo.View_OCC_ALL as o 
	ON dog.fin_id=o.fin_id 
	and dog.build_id=o.bldn_id
  JOIN dbo.View_PAYM as p 
	ON dog.fin_id=p.fin_id 
	and dog.sup_id=p.sup_id 
	and dog.service_id=p.service_id
  JOIN dbo.View_BUILD_ALL as b 
	ON o.fin_id=b.fin_id 
	and o.bldn_id=b.bldn_id
	and o.occ=p.occ
where 1=1
	AND dog.fin_id=@fin_id
	AND b.tip_id=COALESCE(@tip,b.tip_id)
	AND dog.sup_id= COALESCE(@sup_id,dog.sup_id)
OPTION (MAXDOP 1, FAST 10);
go

