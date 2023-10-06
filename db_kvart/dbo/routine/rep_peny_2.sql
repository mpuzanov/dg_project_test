CREATE   PROCEDURE [dbo].[rep_peny_2]
(
	  @fin_id1 SMALLINT
	, @tip_id1 SMALLINT
	, @div_id1 SMALLINT = NULL
)
AS
	--
	-- Пени по участкам
	-- отчет: peny2.fr3
	--
	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)


	SELECT b.adres AS 'Дом'
		 , SUM(oh.penalty_old) AS penalty_old
		 , SUM(oh.penalty_value) AS penalty_value
		 , SUM(oh.penalty_old_new) AS penalty_old_new
		 , SUM(oh.penalty_value + oh.penalty_old_new) AS itogo
		 , SUM(oh.PaymAccount_peny) AS PaymAccount_peny
		 , SUM(oh.Penalty_added) AS penalty_add
	FROM dbo.View_occ_all AS oh 
		JOIN dbo.View_build_all AS b 
			ON oh.bldn_id = b.bldn_id
			AND oh.fin_id = b.fin_id
	WHERE 
		oh.fin_id = @fin_id1
		AND (b.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		AND (b.div_id = @div_id1 OR @div_id1 IS NULL)
	GROUP BY b.adres
	ORDER BY b.adres
go

