CREATE   PROCEDURE [dbo].[k_show_saldo]
(
	@occ1		 INT
   ,@account_one BIT = 0
   ,@all_serv	 BIT = 0  -- показать все услуги
)
AS
	/*
		--
		-- Показываем текущее начальное сальдо(для редактирования)
		-- если нет конечного сальдо прошлого месяца
		--
		k_show_saldo 700011995,0
		k_show_saldo 670001357,0,1
		k_show_saldo 680003557, 1
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
		t.id
	   ,t.sup_id
	   ,t.short_name
	   ,t.sup_name
	   ,t.SALDO
	   ,t.penalty_prev
	   ,t.value
	   ,t.Debt
	FROM (SELECT
			s.id
		   ,s.name AS short_name
		   ,sa.name AS sup_name
		   ,COALESCE(p.saldo, 0) AS saldo
		   ,COALESCE(p.penalty_prev, 0) AS penalty_prev
		   ,COALESCE(p.value, 0) AS value
		   ,COALESCE(ph.debt,0) AS debt
		   ,s.sort_no
		   ,COALESCE(p.sup_id, 0) AS sup_id
		FROM dbo.View_services AS s
		JOIN dbo.Paym_list AS p 
			ON p.service_id=s.id
			AND p.Occ = @occ1
			AND p.fin_id = @fin_current
			AND (p.account_one = @account_one)			
		LEFT JOIN dbo.Suppliers_all sa 
			ON p.sup_id = sa.id
		LEFT JOIN dbo.Paym_history ph 
			ON ph.Occ = @occ1
			AND ph.fin_id = @fin_pred
			AND ph.service_id = s.id
			AND ph.sup_id = p.sup_id
			) AS t
	WHERE (@all_serv = 0
	AND (SALDO <> 0
	OR value <> 0
	OR Debt <> 0))
	OR @all_serv = CAST(1 AS BIT)
	ORDER BY CASE   -- если не сходиться показываем сверху
		WHEN t.SALDO <> t.Debt THEN Null
		ELSE t.short_name
	END
go

