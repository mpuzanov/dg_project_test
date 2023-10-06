CREATE   PROCEDURE [dbo].[k_show_peny_serv]
(
	@occ1		 INT
   ,@sup_id		 INT = NULL
   ,@all_serv	 BIT = 0  -- показать все услуги
)
AS
/*
		
	Показываем текущее начальное пени(для редактирования)
	если нет конечного пени прошлого месяца

	exec k_show_peny_serv 30062,null,1
	exec k_show_peny_serv 30062,345
	exec k_show_peny_serv 30062

*/
	SET NOCOUNT ON;

	IF @all_serv IS NULL
		SET @all_serv = 0;

	DECLARE @fin_pred	 SMALLINT -- предыдушщий фин. период
		   ,@fin_current SMALLINT;
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1);
	SELECT
		@fin_pred = @fin_current - 1;

	SELECT
		@occ1 as occ
	   ,t.service_id
	   ,t.sup_id
	   ,t.short_name
	   ,t.sup_name
	   ,t.debt_peny_history
	   ,t.penalty_prev
	   ,t.paymaccount_peny
	   ,t.penalty_serv
	   ,t.debt_peny	   
	FROM (SELECT
		   p.service_id
		   ,s.short_name AS short_name
		   ,sa.name AS sup_name
		   ,p.penalty_prev AS penalty_prev
		   ,p.penalty_serv AS penalty_serv
		   ,p.paymaccount_peny AS paymaccount_peny
		   ,(p.penalty_serv+p.penalty_prev-p.paymaccount_peny) AS debt_peny
		   ,COALESCE(ph.penalty_serv,0)+COALESCE(ph.penalty_old,0) AS debt_peny_history
		   ,s.sort_no
		   ,p.sup_id AS sup_id
		   ,p.source_id
		   ,p.mode_id
		FROM dbo.View_services AS s 	
		JOIN dbo.Paym_list AS p 
			ON p.service_id=s.id
			AND p.Occ = @occ1
			AND p.fin_id = @fin_current
			AND (@sup_id is null OR p.sup_id = @sup_id)			
		LEFT JOIN dbo.Suppliers_all sa 
			ON p.sup_id = sa.id
		LEFT JOIN dbo.Paym_history ph 
			ON ph.Occ = @occ1
			AND ph.fin_id = @fin_pred
			AND ph.service_id = s.id
			AND ph.sup_id = p.sup_id
			) AS t
	WHERE (@all_serv = 0
		AND (penalty_prev <> 0 OR penalty_serv <> 0	OR debt_peny <> 0 OR t.debt_peny_history <> 0)
		)
		OR (@all_serv = CAST(1 AS BIT)
		AND (source_id%1000<>0 OR t.mode_id%1000<>0)
		)
	ORDER BY CASE   -- если не сходиться показываем сверху
		WHEN t.penalty_prev <> t.debt_peny_history THEN Null
		ELSE t.short_name
	END
go

