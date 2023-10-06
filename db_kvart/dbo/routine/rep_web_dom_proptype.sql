-- =============================================
-- Author:		Антропов
-- Create date: 18.01.2008
-- Description:	web отчёт
-- =============================================
CREATE     PROCEDURE [dbo].[rep_web_dom_proptype]
(
@tip_id1 SMALLINT = NULL
)
AS
BEGIN

	SET NOCOUNT ON;

drop table if exists #t1;
CREATE	TABLE #t1
(
bldn_id		INT
,div		INT
,jeu		SMALLINT
,sname		VARCHAR (50)
,nom_dom	VARCHAR (10)
,kolpeople	INT
)

drop table if exists #nepr;
CREATE	TABLE #nepr
(
bldn_id		INT
,div		INT
,jeu		SMALLINT
,sname		VARCHAR (50)
,nom_dom	VARCHAR (10)
,kol_occ	INT
,total_sq	DECIMAL(9,2)
)

drop table if exists #priv;
CREATE	TABLE #priv
(
bldn_id		INT
,div		INT
,jeu		SMALLINT
,sname		VARCHAR (50)
,nom_dom	VARCHAR (10)
,kol_occ	INT
,total_sq	DECIMAL(9,2)
)

drop table if exists #kupl;
CREATE	TABLE #kupl
(
bldn_id		INT
,div		INT
,jeu		SMALLINT
,sname		VARCHAR (50)
,nom_dom	VARCHAR (10)
,kol_occ	INT
,total_sq	DECIMAL(9,2)
)

drop table if exists #aren;
CREATE	TABLE #aren
(
bldn_id		INT
,div		INT
,jeu		SMALLINT
,sname		VARCHAR (50)
,nom_dom	VARCHAR (10)
,kol_occ	INT
,total_sq	DECIMAL(9,2)
)
INSERT INTO #t1
SELECT	b1.id
	,d1.id
	,o1.jeu
	,s1.name
	,b1.nom_dom
	,COUNT(p1.occ)
FROM	dbo.VOCC AS o1 ,
	dbo.FLATS AS f1 ,
	dbo.BUILDINGS AS b1 ,
	dbo.VSTREETS AS s1 ,
	dbo.divisions AS d1,
	dbo.people AS p1
WHERE	o1.flat_id=f1.id
	AND o1.occ=p1.occ
	AND p1.del=0
	AND f1.bldn_id=b1.id  
	AND b1.street_id=s1.id
	AND b1.div_id=d1.id
	AND o1.status_id<>'закр'
	AND b1.tip_id=COALESCE(@tip_id1,b1.tip_id)
GROUP BY b1.id,d1.id,o1.jeu, s1.name,b1.nom_dom

INSERT INTO #nepr
SELECT	b1.id
	,d1.id
	,o1.jeu
	,s1.name
	,b1.nom_dom
	,COUNT(o1.occ)
	,SUM(o1.total_sq)
FROM	dbo.VOCC AS o1 ,
	dbo.FLATS AS f1 ,
	dbo.BUILDINGS AS b1 ,
	dbo.VSTREETS AS s1 ,
	dbo.divisions AS d1
WHERE	o1.flat_id=f1.id
	AND f1.bldn_id=b1.id  
	AND b1.street_id=s1.id
	AND b1.div_id=d1.id
	AND o1.status_id<>'закр'
	AND o1.proptype_id='непр'
	AND b1.tip_id=COALESCE(@tip_id1,b1.tip_id)
GROUP BY b1.id,d1.id,o1.jeu, s1.name,b1.nom_dom

INSERT INTO #priv
SELECT	b1.id
	,d1.id
	,o1.jeu
	,s1.name
	,b1.nom_dom
	,COUNT(o1.occ)
	,SUM(o1.total_sq)
FROM	dbo.VOCC AS o1 ,
	dbo.FLATS AS f1 ,
	dbo.BUILDINGS AS b1 ,
	dbo.VSTREETS AS s1 ,
	dbo.divisions AS d1
WHERE	o1.flat_id=f1.id
	AND f1.bldn_id=b1.id  
	AND b1.street_id=s1.id
	AND b1.div_id=d1.id
	AND o1.status_id<>'закр'
	AND o1.proptype_id='прив'
	AND b1.tip_id=COALESCE(@tip_id1,b1.tip_id)
GROUP BY b1.id,d1.id,o1.jeu, s1.name,b1.nom_dom

INSERT INTO #kupl
SELECT	b1.id
	,d1.id
	,o1.jeu
	,s1.name
	,b1.nom_dom
	,COUNT(o1.occ)
	,SUM(o1.total_sq)
FROM	dbo.VOCC AS o1 ,
	dbo.FLATS AS f1 ,
	dbo.BUILDINGS AS b1 ,
	dbo.VSTREETS AS s1 ,
	dbo.divisions AS d1
WHERE	o1.flat_id=f1.id
	AND f1.bldn_id=b1.id  
	AND b1.street_id=s1.id
	AND b1.div_id=d1.id
	AND o1.status_id<>'закр'
	AND o1.proptype_id='купл'
	AND b1.tip_id=COALESCE(@tip_id1,b1.tip_id)
GROUP BY b1.id,d1.id,o1.jeu, s1.name,b1.nom_dom

INSERT INTO #aren
SELECT	b1.id
	,d1.id
	,o1.jeu
	,s1.name
	,b1.nom_dom
	,COUNT(o1.occ)
	,SUM(o1.total_sq)
FROM	dbo.VOCC AS o1,
	dbo.FLATS AS f1,
	dbo.BUILDINGS AS b1,
	dbo.VSTREETS AS s1,
	dbo.divisions AS d1
WHERE	o1.flat_id=f1.id
	AND f1.bldn_id=b1.id  
	AND b1.street_id=s1.id
	AND b1.div_id=d1.id
	AND o1.status_id<>'закр'
	AND o1.proptype_id='арен'
	AND b1.tip_id=COALESCE(@tip_id1,b1.tip_id)
GROUP BY b1.id,d1.id,o1.jeu, s1.name,b1.nom_dom

SELECT	b.id
	,d.id
	,o.jeu
	,s.name
	,b.nom_dom
	,SUM(o.total_sq) AS 'total_sq'
	,COUNT(o.occ) AS 'count_occ'
	,#t1.kolpeople
	,#nepr.kol_occ AS 'kol_occ_nepr'
	,#nepr.total_sq AS 'total_sq_nepr'
	,#priv.kol_occ AS 'kol_occ_priv'
	,#priv.total_sq AS 'total_sq_priv'
	,#kupl.kol_occ AS 'kol_occ_kupl'
	,#kupl.total_sq AS 'total_sq_kupl'
	,#aren.kol_occ AS 'kol_occ_aren'
	,#aren.total_sq AS 'total_sq_aren'
FROM dbo.VOCC AS o 
	,dbo.FLATS AS f
	,dbo.BUILDINGS AS b  LEFT OUTER JOIN #t1 ON #t1.bldn_id=b.id
					LEFT OUTER JOIN #nepr ON #nepr.bldn_id=b.id
					LEFT OUTER JOIN #priv ON #priv.bldn_id=b.id
					LEFT OUTER JOIN #kupl ON #kupl.bldn_id=b.id
					LEFT OUTER JOIN #aren ON #aren.bldn_id=b.id
	,dbo.VSTREETS AS s 
	,dbo.divisions AS d
	--,#t1
WHERE	o.flat_id=f.id
	AND f.bldn_id=b.id  
	AND b.street_id=s.id
	AND b.div_id=d.id
	AND o.status_id<>'закр'
	AND b.tip_id=COALESCE(@tip_id1,b.tip_id)
GROUP BY b.id,b.nom_dom, d.id,o.jeu, s.name,b.nom_dom,#t1.kolpeople
	,#nepr.kol_occ,#nepr.total_sq
	,#priv.kol_occ,#priv.total_sq
	,#kupl.kol_occ,#kupl.total_sq
	,#aren.kol_occ,#aren.total_sq
ORDER BY s.name, dbo.Fun_SortDom(b.nom_dom)

drop table if exists #t1;
drop table if exists #nepr;
drop table if exists #priv;
drop table if exists #kupl;
drop table if exists #aren;

END
go

