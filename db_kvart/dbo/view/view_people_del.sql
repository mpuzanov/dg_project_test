-- dbo.view_people_del source

CREATE   VIEW [dbo].[view_people_del]
AS
	SELECT gv.start_date AS 'Период'
		 , o.tip_name AS 'Тип фонда'
		 , vb.div_name AS 'Район'
		 , vb.sector_name AS 'Участок'
		 , CONCAT(vb.street_name , ' д.' , vb.nom_dom) AS 'Адрес дома'
		 , vb.street_name AS 'Улица'
		 , vb.nom_dom AS 'Номер дома'
		 , o.nom_kvr AS 'Квартира'
		 , p.Occ AS 'Лицевой'
		 , p.Last_name AS 'Фамилия'
		 , p.First_name AS 'Имя'
		 , p.Second_name AS 'Отчество'
		 , p.Birthdate AS 'Дата рождения'
		 , p.DateReg AS 'Дата регистрации'
		 , p.DateDel AS 'Дата выписки'
		 , p.DateEnd AS 'Дата окон. регистрации'
		 , p.DateDeath AS 'Дата смерти'
		 , CASE
			   WHEN p.sex = 1 THEN 'мужчина'
			   WHEN p.sex = 0 THEN 'женщина'
			   ELSE '-'
		   END AS 'Пол'
		 , ps.name AS 'Статус регистрации'
		 , fr.name AS 'Род.отнош'
		 , CONCAT(RTRIM(p.Last_name),' ',LEFT(p.First_name,1),'. ',LEFT(p.Second_name,1),'.') AS 'ФИО'
		 , p.id AS 'Код гражданина'
		 , gv.fin_id AS fin_id
		 , o.tip_id
		 , o.bldn_id
		 , o.nom_kvr_sort
		 , vb.nom_dom_sort
		 , CONCAT(vb.street_name , vb.nom_dom_sort) AS sort_dom
	FROM dbo.People AS p
		JOIN dbo.Person_statuses ps 
			ON p.Status2_id = ps.id
		LEFT JOIN dbo.Fam_relations AS fr 
			ON p.Fam_id = fr.id
		JOIN dbo.VOcc o 
			ON p.Occ = o.Occ
		JOIN dbo.Global_values gv 
			ON p.DateDel BETWEEN gv.start_date AND gv.end_date
		JOIN dbo.View_buildings vb 
			ON o.bldn_id = vb.id
	WHERE p.Del = CAST(1 AS BIT);
go

