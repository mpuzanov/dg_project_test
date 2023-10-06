CREATE   PROCEDURE [dbo].[rep_20_2]
--  Ведомость по лицевым счетам  "Список льготников"
(
	@fin_id1	SMALLINT	= NULL
	,@div_id1	SMALLINT	= NULL
	,@lgota_id1	SMALLINT	= NULL
	,@tip		SMALLINT	= NULL
)
AS	
/*
Списки льготников 
1) в заданном месяце
2) по районам
3) по шифрам льгот

дата создания: 11.03.2004
автор: Пузанов М.А.
	
дата последней модификации: 1.04.2009
автор изменений:
	
*/

SET NOCOUNT ON

IF @fin_id1 IS NULL
	SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

-- ограничиваем выборку
IF @tip IS NULL
	AND @lgota_id1 IS NULL
	AND @div_id1 IS NULL
	SET @tip = 0

SELECT
	ph.id
	,ph.Last_name
	,ph.First_name
	,ph.Second_name
	,ph.occ
	,ph.Birthdate
	,o.address
	,s.name AS street_name
	,b.nom_dom
	,f.nom_kvr
	,SUBSTRING(do.doc, 1, 30) AS doc
	,do.issued
	,do.issued2
	,ph.Lgota_id
	,o.total_sq
FROM dbo.DSC_OWNERS AS do
JOIN dbo.View_PEOPLE_ALL AS ph 
	ON do.owner_id = ph.id
	AND do.id = ph.lgota_kod
JOIN dbo.OCCUPATIONS AS o 
	ON ph.occ = o.occ
JOIN dbo.VOCC_TYPES_ALL AS VTA 
	ON o.tip_id = VTA.id
	AND VTA.fin_id = ph.fin_id
JOIN dbo.FLATS AS f 
	ON o.flat_id = f.id
JOIN dbo.BUILDINGS AS b
	ON f.bldn_id = b.id
JOIN dbo.VSTREETS AS s 
	ON b.street_id = s.id
WHERE 
	ph.fin_id = @fin_id1
	AND ph.Lgota_id > 0
	AND o.tip_id = COALESCE(@tip, o.tip_id)
	AND b.div_id = COALESCE(@div_id1, b.div_id)
	AND ph.Lgota_id = COALESCE(@lgota_id1, ph.Lgota_id)
ORDER BY ph.Last_name, ph.First_name, ph.Second_name
go

