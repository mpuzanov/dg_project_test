CREATE   PROCEDURE [dbo].[rep_spiski]
(
	@tip_id1		SMALLINT	= NULL -- Код типа жилого фонда 
	,@div_id1		SMALLINT	= NULL -- код района
	,@sex			SMALLINT	= NULL --код пол(муж=1 жен=0)
	,@jeu1			INT			= NULL -- код участка
	,@date1			DATETIME	= NULL --нижний  ограничитель дат рождений
	,@date2			DATETIME	= NULL --верхний ограничитель дат рождений
	,@build_id1		INT			= NULL -- код дома
	,@count_row1	INT			= NULL -- кол-во строк по умолчанию
	,@is_value		BIT			= NULL -- признак начисления
)
AS
/*

автор:			Пузанов
дата создания:		12.10.04
дата изменеия:	03/09/2008	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	.fr3
в веб-отчетах - списки людей

rep_spiski 28

*/
	SET NOCOUNT ON;

	SET @is_value=COALESCE(@is_value,0)

	IF @count_row1 IS NULL
		AND @tip_id1 IS NULL
		AND @div_id1 IS NULL
		AND @jeu1 IS NULL
		AND @build_id1 IS NULL
		SET @count_row1 = 1000
	ELSE
		SET @count_row1 = 999999

	IF (@sex IS NOT NULL)
		AND (@sex > 1)
		SET @sex = NULL

	SELECT TOP (@count_row1)
		ROW_NUMBER() OVER (ORDER BY b.street_name, b.nom_dom_sort, o.nom_kvr_sort) AS Rownum
		,p.last_name
		,p.first_name
		,p.second_name
		,p.birthdate
		,CONVERT(VARCHAR(8), COALESCE(p.birthdate, ''), 112) AS drog_str
		,CASE
				WHEN p.sex = 1 THEN 'муж'
				WHEN p.sex = 0 THEN 'жен'
				ELSE ''
		END AS sex
		,b.town_name
		,b.street_name AS 'street'
		,b.nom_dom
		,o.nom_kvr
		,b.div_name AS 'div'
		,b.div_id
		,b.tip_id
		,COALESCE(do.DOCTYPE_ID, '-') AS doc
		,COALESCE(do.PASSSER_NO, '-') AS doc_seriy
		,COALESCE(do.doc_no, '-') AS doc_no
		,CONVERT(CHAR(10), do.ISSUED, 104) AS [data]
		,COALESCE(do.DOCORG, '-') AS doc_org
		,do.kod_pvs AS kod_pvs
		,ps.name AS [Status]
		,DateReg
		,CONVERT(VARCHAR(8), COALESCE(DateReg, ''), 112) AS DateReg_str
		,p.DateEnd
		,lgota_id
		,Fam_id
		,o.occ -- для экспорта
		,p.id -- для экспорта
		,o.bldn_id -- для экспорта
		,o.TOTAL_SQ -- для экспорта
	FROM dbo.PEOPLE AS p 
	LEFT OUTER JOIN dbo.IDDOC AS do
		ON p.id = do.owner_id
		AND do.active = 1
	JOIN dbo.VOCC AS o 
		ON p.occ = o.occ
	JOIN dbo.VIEW_BUILDINGS AS b 
		ON o.bldn_id = b.id
	LEFT JOIN  dbo.PERSON_STATUSES AS ps 
		ON p.status2_id = ps.id
	WHERE 
		p.Del = CAST(0 AS BIT)
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR b.id = @build_id1) 
		AND (@div_id1 IS NULL OR b.div_id = @div_id1) 
		AND (@jeu1 IS NULL OR b.sector_id = @jeu1) 
		AND COALESCE(p.sex, 2) = COALESCE(@sex, COALESCE(p.sex, 2))
		AND COALESCE(p.birthdate, '19000101') BETWEEN COALESCE(@date1, '18990101') AND COALESCE(@date2, '20500101')
		AND COALESCE(o.PaidAll, 0) >
			CASE
				WHEN @is_value = CAST(1 AS BIT) THEN 0
				ELSE -999999
			END
	ORDER BY b.street_name
		, b.nom_dom_sort
		, o.nom_kvr_sort
go

