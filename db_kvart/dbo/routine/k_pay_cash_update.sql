-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Раскидка платежа для чека фискализации
-- =============================================
CREATE         PROCEDURE [dbo].[k_pay_cash_update]
(
	  @occ1 INT
	, @paying_id1 INT = NULL -- код платежа для раскидки по чеку	
)
AS
/*
k_pay_cash_update @occ1=680001025 ,@paying_id1=828102
*/
BEGIN
	SET NOCOUNT ON;

	IF @paying_id1 IS NULL
		RETURN

	DELETE pc
	FROM dbo.Paying_cash pc
	JOIN dbo.Payings as p ON pc.paying_id=p.id
	WHERE p.Occ = @occ1
		AND (pc.paying_id = @paying_id1)

	IF EXISTS (
			SELECT *
			FROM dbo.Occupations o 
				JOIN dbo.Occupation_Types ot ON o.tip_id = ot.id
			WHERE o.Occ = @occ1
				AND ot.is_cash_serv = 1
		)
	BEGIN
		INSERT INTO dbo.Paying_cash (paying_id
								   , [service_name]
								   , value_cash)
		SELECT @paying_id1 AS paying_id
			 , t.service_name_kvit
			 , SUM(t.Value) AS value_cash
		FROM (
			SELECT ps.service_id
				 , vs.service_name_kvit
				 , ps.Value				 
			FROM dbo.Occupations o 
				JOIN dbo.Flats f ON o.flat_id = f.id
				JOIN dbo.Paying_serv ps ON o.occ = ps.occ
				JOIN dbo.View_services_kvit vs ON ps.service_id = vs.service_id
					AND o.tip_id = vs.tip_id
					AND f.bldn_id = vs.build_id
			WHERE o.occ = @occ1
				AND (ps.paying_id = @paying_id1)
		) AS t
		GROUP BY t.service_name_kvit
	END



--MERGE dbo.PAYING_CASH AS target USING (SELECT
--		@occ1 AS occ
--	   ,@paying_id1 AS paying_id
--	   ,t.service_name_kvit
--	   ,SUM(t.value) AS value_cash
--	FROM (SELECT
--			ps.occ
--		   ,ps.service_id
--		   ,ps.value
--		   ,vs.service_name_kvit
--		FROM dbo.OCCUPATIONS o
--		JOIN dbo.FLATS f 
--			ON o.flat_id = f.id
--		JOIN dbo.PAYING_SERV ps
--			ON o.occ = ps.occ
--		JOIN dbo.View_SERVICES_Kvit vs
--			ON ps.service_id = vs.service_id
--			AND o.tip_id = vs.tip_id
--			AND f.bldn_id = vs.build_id
--		WHERE o.occ = @occ1
--		AND ps.paying_id = @paying_id1) AS t
--	GROUP BY t.service_name_kvit
----ORDER BY value_cash DESC
--) AS source (occ, paying_id, service_name_kvit, value_cash)
--ON (target.occ = source.occ
--	AND target.paying_id = source.paying_id
--	AND target.service_name = source.service_name_kvit)
--WHEN MATCHED
--	THEN UPDATE
--		SET target.value_cash = source.value_cash
--WHEN NOT MATCHED
--	THEN INSERT
--		(occ
--		,paying_id
--		,[service_name]
--		,value_cash)
--		VALUES (occ
--			   ,paying_id
--			   ,service_name_kvit
--			   ,value_cash)
--;

END
go

