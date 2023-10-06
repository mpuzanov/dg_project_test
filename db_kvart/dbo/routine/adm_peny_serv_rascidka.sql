CREATE   PROCEDURE [dbo].[adm_peny_serv_rascidka]
(
	@tip_id SMALLINT = NULL
   ,@debug  BIT		 = 0
)
/*
Проверка раскидки пени по услугам (для JOBS)

exec adm_peny_serv_rascidka @tip_id=1, @debug=1

*/
AS
	SET NOCOUNT ON

	DECLARE @occ1	  INT
		   ,@strerror VARCHAR(4000)
		   ,@fin_id1  SMALLINT
		   ,@i		  INT = 0
		   ,@date1	  DATETIME

	SET @date1 = current_timestamp

	BEGIN TRY

		DECLARE curs CURSOR LOCAL FOR

		SELECT o.occ
			   ,o.fin_id
		FROM dbo.Occupations AS o 
		OUTER APPLY (
			SELECT SUM(pl.Penalty_old + pl.penalty_serv) AS Penalty_itog
				 , SUM(pl.Penalty_old) AS Penalty_old_new
				 , SUM(pl.Penalty_old + pl.PaymAccount_peny) AS Penalty_old
			FROM dbo.View_paym AS pl 
			WHERE pl.occ = o.occ
				AND pl.fin_id = o.fin_id
				AND pl.sup_id = 0
			) AS t
		WHERE o.status_id <> 'закр'
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (o.penalty_value <> 0 OR o.Penalty_old_new <> 0)
			AND (
				((o.penalty_old_new+o.penalty_added)+o.penalty_value) <> t.Penalty_itog 
				OR o.Penalty_old_new <> t.Penalty_old_new 
				OR o.Penalty_old <> t.Penalty_old
				)
		OPTION (RECOMPILE, MAXDOP 1)

			--SELECT
			--	o.occ
			--   ,o.fin_id
			----,value = (o.penalty_value + o.Penalty_old_new)
			----,comments = '11.Пени на л.сч <> Пени по услугам'
			--FROM dbo.Occupations AS o 
			--WHERE 
			--	o.STATUS_ID <> 'закр'
			--	AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			--	AND (o.penalty_value <> 0 OR o.Penalty_old_new <> 0)
			--	AND (
			--	EXISTS (SELECT
			--			1
			--		FROM dbo.View_paym AS pl 
			--		WHERE 
			--			pl.occ = o.occ
			--			AND pl.fin_id = o.fin_id
			--			AND pl.sup_id = 0
			--		GROUP BY pl.occ
			--		HAVING (SUM(COALESCE(pl.Penalty_old, 0) + COALESCE(pl.penalty_serv, 0)) <>
			--		(o.penalty_value + o.Penalty_old_new)))
			--	OR NOT EXISTS (SELECT
			--			1
			--		FROM dbo.View_paym AS pl 
			--		WHERE 
			--			pl.occ = o.occ
			--			AND pl.fin_id = o.fin_id
			--			AND pl.sup_id = 0)
			--	)
			--OPTION (MAXDOP 1)

		OPEN curs
		FETCH NEXT FROM curs INTO @occ1, @fin_id1
		WHILE (@@fetch_status = 0)
		BEGIN
			SET @i = @i + 1
			IF @debug = 1
				RAISERROR (' %d %d %d', 10, 1, @i, @occ1, @fin_id1) WITH NOWAIT;

			EXEC dbo.k_raschet_peny_serv_old @occ = @occ1
											,@fin_id = @fin_id1

			-- Раскидка пени по услугам по лицевому счёту
			EXEC dbo.k_raschet_peny_serv @occ = @occ1
										,@fin_id = @fin_id1

			FETCH NEXT FROM curs INTO @occ1, @fin_id1
		END
		CLOSE curs
		DEALLOCATE curs

		SET @date1 = current_timestamp - @date1
		IF @debug = 1
			PRINT CONVERT(VARCHAR(25), @date1, 108)

	END TRY

	BEGIN CATCH

		EXECUTE k_GetErrorInfo @visible = @debug
							  ,@strerror = @strerror OUT
		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ1))
		IF @@trancount > 0
			ROLLBACK TRAN
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

