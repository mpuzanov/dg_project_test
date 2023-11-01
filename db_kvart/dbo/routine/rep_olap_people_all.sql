-- =============================================
-- Author:		Пузанов
-- Create date: 15.05.2020
-- Description:	информация по гражданам без привязки к периоду
-- =============================================
CREATE               PROCEDURE [dbo].[rep_olap_people_all]
(
	  @build INT = NULL
	, @tip_id SMALLINT = NULL
	, @sup_id INT = NULL
)
AS
/*
По гражданам

rep_olap_people_all @tip_id=2

*/
BEGIN
	SET NOCOUNT ON;


	DECLARE @start_date SMALLDATETIME = current_timestamp

	SELECT *
		 , CASE
			   WHEN [Возраст] BETWEEN 0 AND 6 THEN '01 (0-6)'
			   WHEN [Возраст] BETWEEN 7 AND 14 THEN '02 (7-14)'
			   WHEN [Возраст] BETWEEN 15 AND 20 THEN '03 (15-20)'
			   WHEN [Возраст] BETWEEN 21 AND 30 THEN '04 (21-30)'
			   WHEN [Возраст] BETWEEN 31 AND 40 THEN '05 (31-40)'
			   WHEN [Возраст] BETWEEN 41 AND 50 THEN '06 (41-50)'	
			   WHEN [Возраст] BETWEEN 51 AND 54 THEN '07 (51-54)'
			   WHEN [Возраст] BETWEEN 55 AND 65 THEN '08 (55-65)'
			   WHEN [Возраст] BETWEEN 66 AND 70 THEN '09 (66-70)'
			   WHEN [Возраст] BETWEEN 71 AND 80 THEN '10 (71-80)'
			   WHEN [Возраст] >= 81 THEN N'11 (81 и старше)'
		   END
		   AS 'Возрастная группа'
	FROM (
		SELECT @start_date AS 'Период'
			 , ba.town_name AS 'Населённый пункт'
			 , ba.tip_name AS 'Тип фонда'
			 , ba.div_name AS 'Район'
			 , ba.sector_name AS 'Участок'
			 , ba.adres AS 'Адрес дома'
			 , ba.street_name AS 'Улица'
			 , ba.nom_dom AS 'Номер дома'
			 , o.nom_kvr AS 'Квартира'			 
			 , p.Occ AS 'Лицевой'
			 , p.FIO AS 'Ф.И.О.'
			 , p.last_name AS 'Фамилия'
			 , p.first_name AS 'Имя'
			 , p.second_name AS 'Отчество'
			 , p.birthdate AS 'Дата рождения'
			 , YEAR(p.birthdate) AS 'Год рождения'
			 , CASE
				   WHEN p.sex = 1 THEN N'мужчина'
				   WHEN p.sex = 0 THEN N'женщина'
				   ELSE '-'
			   END AS 'Пол'
			 , PS.name AS 'Статус регистрации'
			 , PT.name AS 'Тип собственности'
			 , fr.name AS 'Родственные отношения'
			 , st.name AS 'Социальный статус'
			 , [dbo].[Fun_GetBetweenDateYear](p.birthdate, @start_date) AS 'Возраст'
			 , p.lgota_id AS 'Льгота'
			 , p.id AS 'Код гражданина'
			 , o.flat_id AS 'Код помещения'
			 , p.people_uid AS 'УИД гражданина'
			 , CASE WHEN(o.PaidAll > 0) THEN N'Да' ELSE N'Нет' END AS 'Начисляем (сумма>0)'
			 , CASE WHEN(o.total_sq > 0) THEN N'Да' ELSE N'Нет' END AS 'Площадь>0'
			 , CASE WHEN(PS.is_paym = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Начисляем по статусу'
			 , CASE WHEN(ba.is_paym_build = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Начисляем дому'
			 , CASE WHEN(PS.is_kolpeople = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Учет в людях'
			 , CASE WHEN(PS.is_registration = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Учет в регистрации'
			 , o.status_id AS 'Статус л/сч'
			 , p.DateReg AS 'Дата регистрации'
			 , p.DateDel AS 'Дата выписки'
			 , p.DateEnd AS 'Дата окончания регистрации'
			 , p.DateDeath AS 'Дата смерти'
			 , p.inn AS 'ИНН'
			 , p.snils AS 'СНИЛС'
			 , p.Contact_info AS 'Контактная информация'
			 , IT.name AS 'Документ'
			 , I.DOCTYPE_ID AS 'Док_код'
			 , I.doc_no AS 'Док_номер'
			 , I.PASSSER_NO AS 'Док_серия'
			 , I.ISSUED AS 'Док_дата_выдачи'
			 , I.DOCORG AS 'Док_кем_выдан'
			 , I.kod_pvs AS 'Док_код_пвс'
			 , CASE
				   WHEN COALESCE(p.Dola_priv1, 0) > 0 AND
					   COALESCE(p.Dola_priv2, 0) > 0 THEN LTRIM(STR(p.Dola_priv1)) + '/' + LTRIM(STR(p.Dola_priv2))
				   WHEN COALESCE(p.Dola_priv1, 0) > 0 AND
					   COALESCE(p.Dola_priv2, 0) = 0 THEN LTRIM(STR(p.Dola_priv1))
				   WHEN COALESCE(p.Dola_priv1, 0) = 0 AND
					   COALESCE(p.Dola_priv2, 0) > 0 THEN '1/' + LTRIM(STR(p.Dola_priv2))
				   ELSE ''
			   END AS 'Доля собственности'
			 , p.DateBeginPrivat AS 'Дата начала права собств.'
			 , p.DateEndPrivat AS 'Дата окон. права собств.'
			 , CONCAT(ba.street_name, ba.nom_dom_sort) AS sort_dom
			 , ba.nom_dom_sort
			 , o.nom_kvr_sort
		FROM dbo.VPeople p 
			JOIN dbo.Person_statuses PS ON 
				p.status2_id = PS.id
			JOIN dbo.VOcc AS o ON 
				p.Occ = o.Occ
			JOIN dbo.View_buildings AS ba ON 
				o.bldn_id = ba.id
			JOIN dbo.Property_types AS PT ON 
				o.proptype_id = PT.id
			LEFT JOIN dbo.Fam_relations fr ON 
				p.Fam_id = fr.id
			LEFT JOIN dbo.Iddoc AS I ON 
				p.id = I.owner_id
				AND I.active = 1
			LEFT JOIN dbo.Iddoc_types AS IT ON 
				I.DOCTYPE_ID = IT.id
			LEFT JOIN dbo.Status as st ON 
				st.id=p.status_id
		WHERE 
			o.status_id <> 'закр'
			AND (@build IS NULL OR o.bldn_id = @build)
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
	) tp
	OPTION (RECOMPILE)

END
go

