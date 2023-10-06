CREATE   PROCEDURE [dbo].[rep_people_occ]
(
	@occ		INT			  = NULL
   ,@only_izm   BIT			  = 0 -- 1- только изменения за период
   ,@start_date SMALLDATETIME = NULL
   ,@end_date   SMALLDATETIME = NULL
   ,@build_id   INT			  = NULL
   ,@tip_id		SMALLINT	  = NULL
)
/*

Выдаем список зарегистрированных граждан в лицевом счёте 

rep_people_occ 300941, 0,'20230601','20230630', 6985, 60
rep_people_occ 680003617,0,'20151101','20160122',1036,28
rep_people_occ NULL,1,'20151101','20160122',1029
*/
AS
	SET NOCOUNT ON


	DECLARE @DateRegNull SMALLDATETIME = '19000101'

	IF @only_izm IS NULL
		SET @only_izm = 0

	IF @end_date IS NULL
		SET @end_date = current_timestamp

	IF @build_id IS NOT NULL
		SET @occ = NULL

	IF @tip_id IS NOT NULL
		SET @occ = NULL

	IF @build_id IS NULL
		AND @occ IS NULL
		AND @tip_id IS NULL
		SET @occ = 0

	SELECT
		tp.*
	FROM (SELECT
			*
		   ,SUM(is_reg) OVER () AS reg
		   ,SUM(is_del) OVER () AS del
		   ,SUM(total_people1) OVER () AS total_1
		   ,SUM(total_people2) OVER () AS total_2
		FROM (SELECT
				p.Last_name
			   ,p.First_name
			   ,p.Second_name
			   ,p.DateReg
			   ,p.Lgota_id
			   ,fam.Name AS fam_name
			   ,p.Birthdate
			   ,p.Status2_id
			   ,ps.Name AS status_reg
			   ,p.Id
			   ,p.DateDel
			   ,p.DateEnd
			   ,p.sex
			   ,O.occ
			   ,O.build_id
			   ,vb.street_name
			   ,vb.nom_dom
			   ,O.nom_kvr
			   ,CASE
					WHEN @only_izm = 0 THEN ''
					WHEN p.DateDel IS NULL THEN 'Регистрация'
					ELSE 'Выписка'
				END AS reason
			   ,vb.nom_dom_sort
			   ,O.nom_kvr_sort
			   ,CASE
					WHEN 
						COALESCE(p.DateReg, @DateRegNull) < @start_date 
							AND (p.DateDel IS NULL OR p.DateDel >= @start_date) 
						THEN 1
					ELSE 0
				END AS total_people1
			   ,CASE
					WHEN DateReg BETWEEN @start_date AND @end_date THEN 1
					ELSE 0
				END AS is_reg
			   ,CASE
					WHEN DateDel BETWEEN @start_date AND @end_date THEN 1
					ELSE 0
				END AS is_del
			   ,CASE
					WHEN COALESCE(p.DateReg, @DateRegNull) < @end_date AND
					(p.DateDel IS NULL OR
					p.DateDel > @end_date) THEN 1
					ELSE 0
				END AS total_people2
			FROM dbo.People AS p 
			JOIN dbo.VOcc AS O 
				ON O.occ = p.occ
			JOIN dbo.View_buildings_lite vb 
				ON O.build_id = vb.Id
			LEFT JOIN dbo.Fam_relations AS fam 
				ON fam.Id = p.Fam_id
			LEFT JOIN dbo.Person_statuses AS ps 
				ON p.Status2_id = ps.Id
			WHERE 
				(p.occ = @occ OR @occ IS NULL)
				AND (O.build_id = @build_id	OR @build_id IS NULL)
				AND (O.tip_id = @tip_id	OR @tip_id IS NULL)
				AND ps.is_kolpeople = 1
			) AS t
		) AS tp
	WHERE 
		(@only_izm = 1
		AND (
			(DateDel BETWEEN @start_date AND @end_date)
			OR 
			(DateReg BETWEEN @start_date AND @end_date)
			)
		)
	OR (@only_izm = 0
		AND (
			COALESCE(DateReg, @DateRegNull) < @start_date 
					AND (DateDel IS NULL OR DateDel >= @start_date) 
			)
		)
	ORDER BY tp.street_name, tp.nom_dom_sort, tp.nom_kvr_sort, tp.DateDel, tp.Birthdate
go

