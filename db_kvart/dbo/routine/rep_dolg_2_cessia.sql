CREATE   PROCEDURE [dbo].[rep_dolg_2_cessia]
(
 @fin_id1 SMALLINT,
 @sup_id INT = NULL,
 @from_cessia BIT = 0  --  1- берем из начальных данных по цессии
)
AS
/*

	17.07.20112

	Задолженность по периодам кол.месяцев по договорам цесии
	Отчет: 
	
	
	EXEC	@return_value = [dbo].[rep_dolg_2_cessia]
		@fin_id1 = 126,
		@sup_id = 315
		
	Пузанов	
*/
SET NOCOUNT ON


IF @from_cessia is NULL set @from_cessia=0

DECLARE @fin_current SMALLINT

DECLARE @dolg TABLE
( 
name varchar(50),
occ_sup INT,
sumdolg DECIMAL(15,2),
paymaccount DECIMAL(15,2),
paid DECIMAL(15,2),
kolmes DECIMAL(5,1)
)

IF @from_cessia=0
	INSERT INTO @dolg
	SELECT ot.Name,
		os.occ_sup,
		os.saldo-os.paymaccount AS sumdolg,
		os.paymaccount,
		os.value,
		coalesce(os.cessia_dolg_mes_old,0) AS kolmes
	FROM dbo.OCC_SUPPLIERS as os 
		JOIN dbo.DOG_SUP as dog  ON os.dog_int=dog.id 
		JOIN dbo.OCCUPATION_TYPES AS ot  ON dog.tip_id=ot.id
	WHERE os.fin_id=@fin_id1
		  AND os.saldo<>0
		  AND os.KolMesDolg>=0
		  AND os.sup_id=COALESCE(@sup_id,os.sup_id)
		  AND dog.is_cessia=1
ELSE
	INSERT INTO @dolg
	SELECT ot.Name,
		os.occ_sup,
		ces.saldo_start AS sumdolg,
		os.paymaccount,
		os.value,
		coalesce(ces.dolg_mes_start,0) AS kolmes
	FROM dbo.OCC_SUPPLIERS as os 
		JOIN dbo.CESSIA as ces ON ces.occ_sup=os.occ_sup
		JOIN dbo.DOG_SUP as dog  ON os.dog_int=dog.id 
		JOIN dbo.OCCUPATION_TYPES AS ot ON dog.tip_id=ot.id
	WHERE os.fin_id=@fin_id1
		  AND os.saldo<>0
		  AND os.KolMesDolg>=0
		  AND os.sup_id=COALESCE(@sup_id,os.sup_id)
		  AND dog.is_cessia=1

SELECT
	name,	

	--COUNT(CASE WHEN dolg.kolmes>=2 AND dolg.kolmes<3 THEN dolg.occ_sup ELSE NULL END) AS ooc3,
	COUNT(CASE WHEN dolg.kolmes<3 THEN dolg.occ_sup ELSE NULL END) AS ooc3,	
	SUM(CASE WHEN dolg.kolmes<3 THEN dolg.sumdolg ELSE 0 END) AS sum3,
	SUM(CASE WHEN dolg.kolmes<3 THEN dolg.paymaccount ELSE 0 END) AS sum_p3,
	SUM(CASE WHEN dolg.kolmes<3 THEN dolg.paid ELSE 0 END) AS sum_v3,
	
	COUNT(CASE WHEN dolg.kolmes>=3 AND dolg.kolmes<6 THEN dolg.occ_sup ELSE NULL END) AS ooc6,
	SUM(CASE WHEN dolg.kolmes>=3 AND dolg.kolmes<6 THEN dolg.sumdolg ELSE 0 END) AS sum6,
	SUM(CASE WHEN dolg.kolmes>=3 AND dolg.kolmes<6 THEN dolg.paymaccount ELSE 0 END) AS sum_p6,
	SUM(CASE WHEN dolg.kolmes>=3 AND dolg.kolmes<6 THEN dolg.paid ELSE 0 END) AS sum_v6,
	
	COUNT(CASE WHEN dolg.kolmes>=6 AND dolg.kolmes<12 THEN dolg.occ_sup ELSE NULL END) AS ooc12,
	SUM(CASE WHEN dolg.kolmes>=6 AND dolg.kolmes<12 THEN dolg.sumdolg ELSE 0 END) AS sum12,
	SUM(CASE WHEN dolg.kolmes>=6 AND dolg.kolmes<12 THEN dolg.paymaccount ELSE 0 END) AS sum_p12,
	SUM(CASE WHEN dolg.kolmes>=6 AND dolg.kolmes<12 THEN dolg.paid ELSE 0 END) AS sum_v12,
	
	COUNT(CASE WHEN dolg.kolmes>=12 AND dolg.kolmes<24 THEN dolg.occ_sup ELSE NULL END) AS ooc24,
	SUM(CASE WHEN dolg.kolmes>=12 AND dolg.kolmes<24 THEN dolg.sumdolg ELSE 0 END) AS sum24,
	SUM(CASE WHEN dolg.kolmes>=12 AND dolg.kolmes<24 THEN dolg.paymaccount ELSE 0 END) AS sum_p24,
	SUM(CASE WHEN dolg.kolmes>=12 AND dolg.kolmes<24 THEN dolg.paid ELSE 0 END) AS sum_v24,
	
	COUNT(CASE WHEN dolg.kolmes>=24 THEN dolg.occ_sup ELSE NULL END) AS ooc25,
	SUM(CASE WHEN dolg.kolmes>=24 THEN dolg.sumdolg ELSE 0 END) AS sum25,
	SUM(CASE WHEN dolg.kolmes>=24 THEN dolg.paymaccount ELSE 0 END) AS sum_p25,
	SUM(CASE WHEN dolg.kolmes>=24 THEN dolg.paid ELSE 0 END) AS sum_v25,
	
	COUNT(dolg.occ_sup) AS occITOG,	
	SUM(dolg.sumdolg) AS sumITOG,
	SUM(dolg.paymaccount) AS sum_p_ITOG,
	SUM(dolg.paid) AS sum_v_ITOG,
	proc_ITOG=CASE
		 WHEN SUM(dolg.sumdolg)=0 THEN 0
		 WHEN SUM(dolg.paymaccount)=0 THEN 0
		 ELSE CONVERT(DECIMAL(15,2),(SUM(dolg.paymaccount)*100/SUM(dolg.sumdolg)) ) 
		END 
FROM @dolg AS dolg
GROUP BY name
ORDER BY name

--select * from @dolg where kolmes=0
--select kolmes, COUNT(*) from @dolg group by kolmes
go

