CREATE   PROCEDURE [dbo].[k_showkomp2]
(
	  @occ1 INT
)
AS
	--
	--  Показываем субсидию по услугам
	--
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT s.short_name
		 , s.sort_no
		 , subsid_norma = ''
		 , tarif = LTRIM(STR(c.tarif, 6, 2))
		 , c.value_socn
		 , c.value_paid
		 , c.value_subs
	FROM dbo.View_compensac AS comp
		JOIN dbo.View_comp_serv AS c ON comp.occ = c.occ
			AND comp.fin_id = c.fin_id
		JOIN dbo.View_services AS s ON c.service_id = s.id
	WHERE comp.occ = @occ1
		AND comp.fin_id = @fin_current
	UNION ALL
	SELECT 'Итого:'
		 , 100
		 , NULL
		 , NULL
		 , COALESCE(SUM(c.value_socn), 0)
		 , COALESCE(SUM(c.value_paid), 0)
		 , COALESCE(SUM(c.value_subs), 0)
	FROM dbo.View_compensac AS comp
		JOIN dbo.View_comp_serv AS c ON comp.occ = c.occ
			AND comp.fin_id = c.fin_id
		JOIN dbo.View_services AS s ON c.service_id = s.id
	WHERE comp.occ = @occ1
		AND comp.fin_id = @fin_current
	ORDER BY s.sort_no
go

