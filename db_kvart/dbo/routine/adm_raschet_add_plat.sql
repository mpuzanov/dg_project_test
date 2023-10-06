-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[adm_raschet_add_plat]
(
	@PrintGroup	SMALLINT
	,@tip_id	SMALLINT
	,@debug		BIT	= 0
)
AS
/*

Расчёт разовых по лучшим платильщикам
5% от постоянных начислений

*/
BEGIN

	SET NOCOUNT ON;

	DECLARE	@i				INT			= 0
			,@y				INT			= 0
			,@occ1			INT
			,@add_type		SMALLINT	= 14
			, -- тип разового "Лучший плательщик"
			@fin_current	SMALLINT
			,@paid			DECIMAL(9, 2)
			,@proc			DECIMAL(10, 4)	= 0.05
			,@comments		VARCHAR(50)	= 'Скидка лучшему плательщику 5%'
			,@doc			VARCHAR(50)	= 'Лучший плательщик 5%'

	DECLARE @t_occ TABLE
		(
			occ			INT
			,service_id	VARCHAR(10)
			,sup_id INT
			,paid		DECIMAL(9, 2)
			,sum_add	DECIMAL(9, 2)
		)

	DECLARE curs CURSOR LOCAL FOR
		SELECT
			o.occ
		FROM dbo.Occupations AS o
		JOIN dbo.Print_occ AS po
			ON o.occ = po.occ
		WHERE group_id = @PrintGroup
		AND o.tip_id = @tip_id

	OPEN curs
	FETCH NEXT FROM curs INTO @occ1
	WHILE (@@fetch_status = 0)
	BEGIN
		SET @i = @i + 1
		IF @debug = 1
			RAISERROR (' %d  %d', 10, 1, @i, @occ1) WITH NOWAIT;

		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

		DELETE FROM @t_occ
		-- 1. Находим общую сумму постоянных начислений по лицевому
		INSERT
		INTO @t_occ
		(	occ
			,service_id
			,sup_id
			,paid
			,sum_add)
				SELECT
					occ
					,service_id
					,sup_id
					,paid
					,0
				FROM dbo.Paym_list
				WHERE fin_id = @fin_current
				AND occ = @occ1

		SELECT
			@paid = SUM(paid)
		FROM @t_occ
		IF @paid > 0
		BEGIN -- Рассчитываем разовые
			SET @y = @y + 1

			UPDATE @t_occ
			SET sum_add = paid * @proc * (-1)
			WHERE paid > 0;

			DELETE FROM dbo.Added_Payments
			WHERE fin_id = @fin_current
				AND occ = @occ1
				AND add_type = @add_type;

			INSERT
			INTO dbo.Added_Payments
			(	occ
				,service_id
				,sup_id
				,add_type
				,doc_no
				,doc
				,value
				,comments)
					SELECT
						occ
						,service_id
						,sup_id
						,@add_type
						,'888'
						,@doc
						,sum_add
						,@comments
					FROM @t_occ
					WHERE sum_add <> 0;

			-- Изменить значения в таблице paym_list
			UPDATE dbo.PAYM_LIST
			SET added = COALESCE((SELECT
					SUM(value)
				FROM dbo.ADDED_PAYMENTS ap
				WHERE 
					ap.occ = @occ1
					AND ap.service_id = pl.service_id
					AND ap.sup_id=pl.sup_id
					AND ap.fin_id = pl.fin_id)
				, 0)
			FROM dbo.Paym_list AS pl
			WHERE occ = @occ1
			AND fin_id = @fin_current;


		END

		FETCH NEXT FROM curs INTO @occ1
	--if @debug=1 IF @i>=1000 BREAK
	END
	CLOSE curs
	DEALLOCATE curs

	SELECT
		'Добавили' = @y


END
go

