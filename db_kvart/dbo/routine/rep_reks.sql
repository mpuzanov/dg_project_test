CREATE   PROCEDURE [dbo].[rep_reks] 
(
@fin_id SMALLINT =NULL
,@tip_id SMALLINT= NULL
)
AS
/*

дата создания: 17.11.08
автор: Пузанов

*/ 

SET NOCOUNT ON


DECLARE @fin_current SMALLINT,  @service_id VARCHAR(10)
SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)
IF @fin_id IS NULL SET @fin_id=@fin_current
IF @tip_id IS NULL SET @tip_id=1

CREATE TABLE #people
(  
occ INT PRIMARY KEY, 
kol_people INT,
) 
  
	INSERT INTO #people
	SELECT	p.occ, COUNT(p.owner_id)
	FROM dbo.View_OCC_ALL AS o 
		JOIN dbo.View_PEOPLE_ALL AS p  ON o.fin_id=p.fin_id and o.occ=p.occ
		JOIN dbo.person_calc AS pc ON p.status2_id=pc.status_id
		JOIN dbo.person_statuses AS ps  ON p.status2_id=ps.id
	WHERE o.tip_id=@tip_id
		AND o.fin_id=@fin_id
		AND ps.is_paym=1
		AND pc.have_paym=1
		AND pc.service_id='элек'
		AND o.status_id<>'закр'		
	GROUP BY p.occ


	SELECT 
		s.name AS 'STREET',
		b.nom_dom AS 'NOM_DOM',
        f.nom_kvr AS 'NOM_KVR'
		,KOL_REG=CASE 
                    WHEN p.kol_people IS NULL THEN 0
					ELSE p.kol_people
				END
        ,LIFT=CASE
                    WHEN cl.mode_id=9001 THEN 1
                    ELSE 0
                END
        ,PLIT=CASE
					WHEN clp.mode_id=12001 THEN 1
					ELSE 0
				END
        ,COALESCE(f.rooms,0) AS ROOMS
        ,COALESCE(f.[floor],0) AS [FLOOR]
	 FROM dbo.View_OCC_ALL AS o 
	    LEFT OUTER JOIN #people AS p ON o.occ=p.occ				
		LEFT OUTER JOIN dbo.View_CONSMODES_ALL AS cl
					ON	cl.service_id='лифт' AND cl.occ=o.occ 
					AND cl.fin_id=@fin_id AND o.fin_id=@fin_id
		LEFT OUTER JOIN dbo.View_CONSMODES_ALL AS clp
					ON	clp.service_id='плит' AND clp.occ=o.occ 
					AND clp.fin_id=@fin_id AND o.fin_id=@fin_id					
		,dbo.VSTREETS AS s
		,dbo.View_BUILD_ALL AS b	
		,dbo.flats AS f
	WHERE	
		o.fin_id=@fin_id
		AND o.status_id<>'закр'
		AND o.tip_id=@tip_id
		AND o.flat_id=f.id
		AND f.bldn_id=b.bldn_id
		AND b.street_id=s.id
		AND o.fin_id=b.fin_id
	ORDER BY s.name, b.nom_dom_sort, f.nom_kvr_sort
go

