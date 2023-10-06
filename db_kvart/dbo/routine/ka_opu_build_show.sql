-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                     PROCEDURE [dbo].[ka_opu_build_show]
(
	@fin_id			SMALLINT
	,@bldn_id		INT			= NULL
	,@tip_id		SMALLINT	= NULL
	,@service_id	VARCHAR(10)	= NULL
	,@fin_id2		SMALLINT	= NULL
)
AS
/*
ka_opu_build_show 244,6789,1,null,244
*/
BEGIN
	SET NOCOUNT ON;

	IF @bldn_id IS NULL
		AND @tip_id IS NULL
		SET @bldn_id = 0
	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id

	-- для ограничения доступа услуг
	CREATE TABLE #s
	(
		id			VARCHAR(10)	COLLATE database_default PRIMARY KEY
		,name		VARCHAR(100) COLLATE database_default
	)
	INSERT
	INTO #s	
	(	id
		,name)
		SELECT
			id
			,name
		FROM dbo.View_services
		
	SELECT
		pcb.*
		,s.name AS serv_name
		,o.nom_kvr
		,u.Initials                                        AS [user_name]
		,vb.street_name
		,vb.nom_dom
		,vb.ID                                             AS bldn_id
		,vm.name AS metod_text  --dbo.Fun_GetMetodText(pcb.metod_old)
		,o.start_date
		,un.short_id
		,o.total_sq                                        AS total_sq
		,CAST((o.total_sq * pcb.koef_day) AS DECIMAL(9,2)) AS total_sq_koef
		,CAST(CASE
                  WHEN COALESCE(cl.is_counter, 0) > 0 THEN 1
                  ELSE 0
        END AS BIT)                                        AS is_counter
		, CASE
              WHEN COUNT(o.nom_kvr) OVER (PARTITION BY o.nom_kvr, pcb.service_id) > 1 THEN 'Да'
              ELSE ''
        END                                                AS double_kvr
	FROM dbo.Paym_occ_build AS pcb
	JOIN dbo.View_occ_all_lite AS o 
		ON pcb.fin_id = o.fin_id
		AND pcb.occ = o.occ
	JOIN #s AS s 
		ON pcb.service_id = s.ID
	JOIN dbo.View_BUILDINGS_LITE AS vb 
		ON o.bldn_id = vb.ID
	LEFT JOIN dbo.USERS AS u
		ON pcb.user_login = u.login
	LEFT JOIN dbo.Units AS un 
		ON pcb.unit_id=un.id
	LEFT OUTER JOIN dbo.Consmodes_list cl ON 
		pcb.occ = cl.occ
		AND pcb.service_id = cl.service_id
		AND pcb.fin_id = cl.fin_id
		AND pcb.sup_id = cl.sup_id
	LEFT JOIN view_metod as vm
		ON pcb.metod_old=vm.id
	WHERE pcb.fin_id BETWEEN @fin_id AND @fin_id2
		AND (o.bldn_id = @bldn_id OR @bldn_id IS NULL)
		AND (o.tip_id = @tip_id OR @tip_id IS NULL)
		AND (pcb.service_id = @service_id OR @service_id IS NULL)
	ORDER BY vb.street_name, vb.nom_dom_sort, o.nom_kvr_sort
	OPTION(RECOMPILE)
END
go

