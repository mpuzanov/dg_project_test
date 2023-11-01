-- =============================================
-- Author:		Пузанов
-- Create date: 28.02.2012
-- Description:	информация по гражданам
-- =============================================
CREATE               PROCEDURE [dbo].[rep_olap_people]
(
	  @build INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @sup_id INT = NULL
)
AS
/*
По гражданам

exec rep_olap_people @build=NULL, @fin_id1=250, @fin_id2=251, @tip_id=1

*/
BEGIN
	SET NOCOUNT ON;


	--IF @build IS NULL AND @tip_id IS NULL AND @sup_id IS NULL SET @build=0
	--print @fin_start

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

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
		SELECT o.start_date AS 'Период'
			 , ba.town_name AS 'Населённый пункт'
			 , ba.tip_name AS 'Тип фонда'
			 , ba.div_name AS 'Район'
			 , ba.sector_name AS 'Участок'
			 , ba.adres AS 'Адрес дома'
			 , ba.street_name AS 'Улица'
			 , ba.nom_dom AS 'Номер дома'
			 , o.nom_kvr AS 'Квартира'
			 , vpa.Occ AS 'Лицевой'
			 , p2.FIO AS 'Ф.И.О.'
			 , vpa.last_name AS 'Фамилия'
			 , vpa.first_name AS 'Имя'
			 , vpa.second_name AS 'Отчество'
			 , vpa.birthdate AS 'Дата рождения'
			 , YEAR(vpa.birthdate) AS 'Год рождения'
			 , CASE
				   WHEN vpa.sex = 1 THEN N'мужчина'
				   WHEN vpa.sex = 0 THEN N'женщина'
				   ELSE '-'
			   END AS 'Пол'
			 , PS.name AS 'Статус регистрации'
			 , PT.name AS 'Тип собственности'
			 , fr.name AS 'Родственные отношения'
			 , [dbo].[Fun_GetBetweenDateYear](vpa.birthdate, o.start_date) AS 'Возраст'
			 , vpa.lgota_id AS 'Льгота'
			 , st.name AS 'Социальный статус'
			 , vpa.ID AS 'Код гражданина'
			 , o.flat_id AS 'Код помещения'
			 , vpa.people_uid AS 'УИД гражданина'
			 , CASE WHEN(o.PaidAll > 0) THEN N'Да' ELSE N'Нет' END AS 'Начисляем (сумма>0)'
			 , CASE WHEN(o.total_sq > 0) THEN N'Да' ELSE N'Нет' END AS 'Площадь>0'
			 , CASE WHEN(PS.is_paym = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Начисляем по статусу'
			 , CASE WHEN(ba.is_paym_build = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Начисляем дому'
			 , CASE WHEN(PS.is_kolpeople = CAST(1 AS BIT)) THEN N'Да' ELSE N'Нет' END AS 'Учет в людях'
			 , CASE WHEN(PS.is_registration = CAST(1 AS BIT)) THEN N'Да'ELSE N'Нет' END AS 'Учет в регистрации'
			 , o.status_id AS 'Статус л/сч'
			 
			 , p2.DateReg AS 'Дата регистрации'
			 , p2.DateDel AS 'Дата выписки'
			 , p2.DateEnd AS 'Дата окончания регистрации'
			 , CASE 
					WHEN p2.AutoDelPeople=1 THEN 'Выписать'
					WHEN p2.AutoDelPeople=2 THEN 'Восстановить статус'
					ELSE '-'
				END AS 'Действие при окончании рег'
			 , p2.DateDeath AS 'Дата смерти'
			 , p2.inn AS 'ИНН'
			 , p2.snils AS 'СНИЛС'
			 , p2.Contact_info AS 'Контактная информация'
			 , p2.email AS 'Эл.почта гражданина'
			 , o2.email AS 'Эл.почта л/сч'
			 , o2.telephon AS 'Телефон л/сч'
			 , o2.id_els_gis AS 'ЕЛС ГИС ЖКХ'
			 , CASE
				   WHEN COALESCE(p2.Dola_priv1, 0) > 0 AND
					   COALESCE(p2.Dola_priv2, 0) > 0 THEN LTRIM(STR(p2.Dola_priv1)) + '/' + LTRIM(STR(p2.Dola_priv2))
				   WHEN COALESCE(p2.Dola_priv1, 0) > 0 AND
					   COALESCE(p2.Dola_priv2, 0) = 0 THEN LTRIM(STR(p2.Dola_priv1))
				   WHEN COALESCE(p2.Dola_priv1, 0) = 0 AND
					   COALESCE(p2.Dola_priv2, 0) > 0 THEN '1/' + LTRIM(STR(p2.Dola_priv2))
				   ELSE ''
			   END AS 'Доля собственности'
			 , p2.DateBeginPrivat AS 'Дата начала права собств.'
			 , p2.DateEndPrivat AS 'Дата окон. права собств.'
			 , IT.name AS 'Документ'
			 , I.DOCTYPE_ID AS 'Док_код'
			 , I.DOC_NO AS 'Док_номер'
			 , I.PASSSER_NO AS 'Док_серия'
			 , I.ISSUED AS 'Док_дата_выдачи'
			 , I.DOCORG AS 'Док_кем_выдан'
			 , I.kod_pvs AS 'Док_код_пвс'
			 , CONCAT(ba.street_name, ba.nom_dom_sort) AS sort_dom
			 , ba.nom_dom_sort
			 , o.nom_kvr_sort
		--, ROW_NUMBER() OVER (PARTITION BY vpa.occ ORDER BY vpa.Birthdate) AS num_people
		FROM dbo.View_people_all vpa 
			JOIN dbo.Person_statuses PS ON 
				vpa.status2_id = PS.ID
			JOIN dbo.VPeople p2 ON 
				vpa.ID = p2.ID
			JOIN dbo.View_occ_all AS o ON 
				vpa.Occ = o.Occ
				AND o.fin_id = vpa.fin_id
			JOIN dbo.Occupations AS o2 ON 
				vpa.Occ = o2.Occ
			JOIN dbo.View_buildings AS ba ON 
				o.bldn_id = ba.ID
			JOIN dbo.Property_types AS PT ON 
				o.proptype_id = PT.ID
			LEFT JOIN dbo.Fam_relations fr ON 
				vpa.Fam_id = fr.ID
			LEFT JOIN dbo.Iddoc AS I ON 
				vpa.owner_id = I.owner_id
				AND I.active = 1
			LEFT JOIN dbo.Iddoc_types AS IT ON 
				I.DOCTYPE_ID = IT.ID
			LEFT JOIN dbo.Status as st ON 
				st.id=vpa.status_id
		WHERE 
			vpa.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@build IS NULL OR o.bldn_id = @build)
			AND o.status_id <> 'закр'
	) tp
	--OPTION (MAXDOP 1)
	OPTION (RECOMPILE)


END
go

