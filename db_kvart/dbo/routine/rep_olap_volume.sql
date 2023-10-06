CREATE   PROCEDURE [dbo].[rep_olap_volume]
(
	  @tip_id SMALLINT
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build INT = NULL
	, @sup_id INT = NULL
	, @debug BIT = NULL
)
AS
/*
Выгрузка объемов по услугам

exec rep_olap_volume @tip_id=4, @fin_id1=250  ,@debug=1
exec rep_olap_volume @tip_id=4, @fin_id1=250, @build=6806  ,@debug=1

*/
SET NOCOUNT ON 

IF @fin_id1 IS NULL 
	AND @fin_id2 IS NULL
	BEGIN
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)
		SELECT @fin_id2 = @fin_id1
	END

SET @fin_id1 = COALESCE(@fin_id1,0)
SET @fin_id2 =  COALESCE(@fin_id2,@fin_id1)

IF @debug=1
	PRINT CONCAT('@tip_id=',@tip_id,', @fin_id1=',@fin_id1,', @fin_id2=',@fin_id2,', @build=',@build,', @sup_id=', @sup_id)

CREATE TABLE #t(
[start_date] SMALLDATETIME
,Occ INT
,nom_kvr VARCHAR(20) COLLATE database_default
,total_sq DECIMAL(12,4)
,roomtype_id VARCHAR(10) COLLATE database_default
,nom_kvr_sort VARCHAR(30) COLLATE database_default
,service_id VARCHAR(10) COLLATE database_default
,serv_name VARCHAR(100) COLLATE database_default
,kol DECIMAL(12,6)
,kol_serv DECIMAL(12,6)
,kol_added DECIMAL(12,6)
,kol_sub DECIMAL(12,6)
,metod_name VARCHAR(30) COLLATE database_default
,is_volume VARCHAR(10) COLLATE database_default
,is_value VARCHAR(10) COLLATE database_default
,kol_day INT
,koef_day DECIMAL(9,4)
,date_start SMALLDATETIME
,date_end SMALLDATETIME
,paid DECIMAL(9,2)
,fio VARCHAR(50) COLLATE database_default
,kol_norma DECIMAL(12,6)
,metod_old_name VARCHAR(30) COLLATE database_default
,metod_old INT default NULL
,total_sq_koef DECIMAL(9,4)
,avg_volume_square DECIMAL(12,6)
)

-- для ограничения доступа услуг
CREATE TABLE #services (
	id VARCHAR(10) COLLATE database_default	--PRIMARY KEY
	, [name] VARCHAR(100) COLLATE database_default
	, is_build BIT
)
	INSERT INTO #services (id, name)
	SELECT vs.id
		 , vs.name
	FROM dbo.services AS vs
	WHERE id in ('отоп','гвод','хвод','элек','тепл','одгж','одхж','одэж','одвж','вотв','одтж')	

DECLARE @fin SMALLINT

DECLARE curs CURSOR LOCAL FOR
	SELECT fin_id, build_id 
	FROM View_build_all_lite 
	WHERE 
		tip_id=@tip_id
		and fin_id BETWEEN @fin_id1 AND @fin_id2 
		and (@build is null OR build_id=@build)
	ORDER BY fin_id

OPEN curs
FETCH NEXT FROM curs INTO @fin, @build
WHILE (@@fetch_status = 0)
BEGIN
	IF @debug=1
		RAISERROR ('%d %d', 10, 1, @fin, @build) WITH NOWAIT;

	INSERT INTO #t
	SELECT 
	  o.start_date as 'Период'
	  ,o.Occ AS 'Лицевой'
	  ,o.nom_kvr_prefix AS 'Квартира'
	  ,o.total_sq AS 'Площадь'
	  ,o.roomtype_id AS 'Тип помещения'
	  ,o.nom_kvr_sort
	  ,coalesce(p.service_id,'') AS 'Код услуги'
	  ,coalesce(s.name,'') AS 'Услуга'
	  ,(coalesce(p.kol,0)+coalesce(p.kol_added,0)-coalesce(t_sub.kol_sub,0)) as 'Кол-во'
	  ,coalesce(p.kol,0)  AS 'Кол по услуге'
	  ,coalesce(p.kol_added,0)-coalesce(t_sub.kol_sub,0) AS 'Кол разовых'
	  ,coalesce(t_sub.kol_sub,0) AS 'Кол субсидий'
	  ,p.metod_name as 'Метод расчета'
	  ,CASE WHEN(coalesce(p.kol,0)<>0 OR coalesce(p.kol_added,0)<>0) THEN 'Да' ELSE'Нет' END AS 'Есть объём'
	  ,CASE WHEN(coalesce(p.value,0)<>0) THEN 'Да' ELSE 'Нет' END AS 'Есть начисления'
	  ,p.kol_day as 'Кол_дней'
	  ,p.koef_day as 'Коэф_дней'
	  ,p.date_start as date_start
	  ,p.date_end as date_end
	  ,p.paid as 'Начислено'
	  ,dbo.Fun_Initials(o.occ) as 'ФИО'
	  ,p.kol_norma AS 'Объём до'
	  ,p.metod_old_name AS 'Метод до'
	  ,p.metod_old
	  ,CAST((o.total_sq * p.koef_day) AS DECIMAL(9,2)) AS 'Площадь_коэф'
	  ,CASE WHEN(bsv.avg_volume_m2>0) THEN bsv.avg_volume_m2 ELSE COALESCE(t_avg.avg_volume, 0) END AS avg_volume_square
	FROM dbo.View_occ_all_lite as o
		LEFT JOIN dbo.View_paym as p ON 
			o.Occ=p.occ 
			and p.fin_id=o.fin_id 
			AND (p.sup_id=@sup_id OR @sup_id IS NULL)
		JOIN #services as s ON p.service_id=s.id
		CROSS APPLY (
			SELECT SUM(va.kol) AS kol_sub
			FROM dbo.View_added_lite va 
			WHERE va.fin_id = p.fin_id
				AND va.occ = p.occ
				AND va.service_id = p.service_id
				AND va.sup_id = p.sup_id
				AND va.add_type = 15
		) AS t_sub
		LEFT JOIN dbo.Build_source_value AS bsv ON 
			bsv.fin_id=o.fin_id 
			AND bsv.build_id=o.build_id 
			AND bsv.service_id=p.service_id
		LEFT JOIN (
			select service_id, avg_volume from dbo.fun_get_avg_volume_square_tf(@fin,@build)
		) AS t_avg ON t_avg.service_id=s.id
	WHERE 
		o.tip_id = @tip_id
		and o.fin_id = @fin
		and o.bldn_id = @build
		--and o.total_sq>0
		and o.status_id<>'закр'	
	--OPTION (RECOMPILE)

	FETCH NEXT FROM curs INTO @fin, @build 
END
CLOSE curs
DEALLOCATE curs


SELECT 
	start_date as 'Период'
  ,Occ AS 'Лицевой'
  ,nom_kvr AS 'Квартира'
  ,total_sq AS 'Площадь'
  ,roomtype_id AS 'Тип помещения'
  ,nom_kvr_sort
  ,service_id AS 'Код услуги'
  ,serv_name AS 'Услуга'
  ,kol as 'Кол-во'
  ,kol_serv AS 'Кол по услуге'
  ,kol_added AS 'Кол разовых'
  ,kol_sub AS 'Кол субсидий'
  ,metod_name as 'Метод расчета'
  ,is_volume AS 'Есть объём'
  ,is_value AS 'Есть начисления'
  ,kol_day as 'Кол_дней'
  ,koef_day as 'Коэф_дней'
  ,date_start as date_start
  ,date_end as date_end
  ,paid as 'Начислено'
  ,fio as 'ФИО'
  ,kol_norma AS 'Объём до'
  ,metod_old_name AS 'Метод до'
  ,total_sq_koef AS 'Площадь_коэф'
  ,avg_volume_square AS 'Сред.объём в доме на м2'
  ,CAST(CASE
	WHEN metod_old<>3 AND avg_volume_square>0 THEN total_sq_koef*avg_volume_square
	ELSE 0
  END AS DECIMAL(15,6)) AS avg_vol 
FROM #t
OPTION (MAXDOP 1);

DROP TABLE IF EXISTS #t;
go

