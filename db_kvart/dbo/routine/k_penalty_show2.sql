CREATE   PROCEDURE [dbo].[k_penalty_show2]
(
	@occ1		INT
	,@fin_id1	SMALLINT	= NULL
)
AS
	/*

	Показывает суммы по задолженности
	
	k_penalty_show2 680004153, 181

	*/

	SET NOCOUNT ON


	IF (@fin_id1 IS NULL)
		OR (@fin_id1 = 0)
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)


	SELECT
		  CASE
				WHEN dolg = 0 THEN NULL
				ELSE dolg
			END AS 'Задолженность'
		, CASE
				WHEN dolg_peny = 0 THEN NULL
				ELSE dolg_peny
		  END AS 'Долг пени'
		, CASE
				WHEN paid_pred = 0 THEN NULL
				ELSE paid_pred
			END AS 'Пред. начисл.'
		, CASE
				WHEN peny_old = 0 THEN NULL
				ELSE peny_old
			END AS 'Пени стар'
		, CASE
				WHEN paymaccount = 0 THEN NULL
				ELSE paymaccount
			END AS 'Оплачено'
		, CASE
				WHEN paymaccount_peny = 0 THEN NULL
				ELSE paymaccount_peny
			END AS 'из них пени'
		, CASE
				WHEN peny_old_new = 0 THEN NULL
				ELSE peny_old_new
			END AS 'Пени стар изм.'
		, CASE
				WHEN kolday = 0 THEN NULL
				ELSE kolday
			END AS 'Дней'
		, CASE
				WHEN penalty_value = 0 THEN NULL
				ELSE penalty_value
			END AS 'Пени'
		, debt_peny AS 'Итого пени'
	FROM (SELECT
			dolg
			,dolg_peny
			,paid_pred
			,peny_old
			,paymaccount
			,paymaccount_peny
			,peny_old_new
			,kolday
			,penalty_value
			,debt_peny
		FROM dbo.View_peny_all AS p 
		WHERE occ = @occ1
		AND fin_id = @fin_id1
		) AS t
go

