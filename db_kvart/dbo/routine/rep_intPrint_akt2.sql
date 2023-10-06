-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE           PROCEDURE [dbo].[rep_intPrint_akt2]
(
	@fin_id			SMALLINT
   ,@tip_id			SMALLINT	  = NULL -- тип жилого фонда
   ,@ops			INT			  = NULL -- ОПС
   ,@sum_dolg		DECIMAL(9, 2) = NULL -- если не равно 0 вывод только с долгом более этой суммы
   ,@group_id		INT			  = NULL
   ,@people0_block  BIT			  = 0
   ,@sup_id			INT			  = NULL
   ,@Param			SMALLINT	  = 1
   ,@paidAll0_block BIT			  = 0 -- блокировать печать где нет начислений
   ,@PROPTYPE_STR   VARCHAR(10)	  = NULL -- строка с разрешёнными к печати типами собственности
   ,@paid_block		BIT			  = 0 -- блокировать печать где есть начисления
)
AS
/*
Используется в отчёте:
Отчет отправленных счёт-квитанций
index2.fr3

exec rep_intPrint_akt2 @fin_id=195

*/
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #t;
	DROP TABLE IF EXISTS #t;

	SET @paidAll0_block = coalesce(@paidAll0_block, 0)
	SET @paid_block = coalesce(@paid_block, 0)

	IF @Param IS NULL
		OR @Param > 3
		SET @Param = 1

	IF @sup_id IS NULL
	BEGIN
		SELECT
			o.occ
		   ,o.flat_id
		   ,COALESCE(o.kol_people, 0) AS kol_people
		   ,o.PROPTYPE_ID
		   ,o.PaidAll
		   ,o.TOTAL_SQ
		INTO #t
		FROM dbo.View_occ_all_lite AS o
		JOIN dbo.INTPRINT AS i 
			ON o.occ = i.occ AND i.fin_id = o.fin_id
		WHERE o.STATUS_ID <> 'закр'
		--AND o.TOTAL_SQ > 0
		AND NOT EXISTS (SELECT
				*
			FROM dbo.OCC_NOT_print AS onp 
			WHERE onp.occ = o.occ)
		AND i.fin_id = @fin_id
		AND i.SumPaym > COALESCE(@sum_dolg, -99999)
		AND (@group_id IS NULL
		OR (@group_id IS NOT NULL
		AND EXISTS (SELECT
				*
			FROM dbo.PRINT_OCC AS po 
			WHERE po.occ = o.occ
			AND po.group_id = @group_id)
		))
		--******************************************************
		IF @people0_block = 1
			DELETE FROM #t
			WHERE kol_people = 0

		-- Убираем печать где нет начислений
		IF @paidAll0_block = 1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll = 0 OR t.TOTAL_SQ = 0

		-- Убираем печать где ЕСТЬ начисления
		IF @paid_block=1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll > 0

		-- Убираем печать где тип собственности не тот
		IF COALESCE(@PROPTYPE_STR, '') <> ''
			DELETE t
				FROM #t AS t
			WHERE NOT EXISTS (SELECT
						1
					FROM STRING_SPLIT(@PROPTYPE_STR, ',')
					WHERE RTRIM(value) <> ''
					AND value = t.PROPTYPE_ID)

		--****************************************************


		--IF @Param = 1 SELECT * FROM #t
		IF @Param = 1
			SELECT
				OPS.name AS OPS
			   ,COUNT(o.occ) AS kolocc
			FROM dbo.OPS 
			JOIN dbo.BUILDINGS AS b
				ON OPS.id = b.index_id
			JOIN dbo.FLATS AS f 
				ON b.id = f.bldn_id
			JOIN #t AS o
				ON f.id = o.flat_id
			WHERE OPS.name NOT IN ('SPDU', 'Уралопторг', 'Коммунал.', 'Скороход')
			AND OPS.print_id = 1
			AND (b.index_id = @ops
			OR @ops IS NULL)
			AND (b.tip_id = @tip_id
			OR @tip_id IS NULL)
			GROUP BY OPS.name
			ORDER BY OPS.name
		--****************************************************	
		IF @Param = 2
			SELECT
				OPS.name AS OPS
			   ,COUNT(o.occ) AS kolocc
			FROM dbo.OPS 
			JOIN dbo.BUILDINGS AS b 
				ON OPS.id = b.index_id
			JOIN dbo.FLATS AS f 
				ON b.id = f.bldn_id
			JOIN #t AS o
				ON f.id = o.flat_id
			WHERE OPS.name IN ('SPDU', 'Уралопторг', 'Коммунал.', 'Скороход')
			--and ops.print_id=1
			AND (b.index_id = @ops
			OR @ops IS NULL)
			AND (b.tip_id = @tip_id
			OR @tip_id IS NULL)
			GROUP BY OPS.name
			ORDER BY OPS.name
		--****************************************************			
		IF @Param = 3
			SELECT
				OPS.name AS OPS
			   ,COUNT(o.occ) AS kolocc
			FROM dbo.OPS 
			JOIN dbo.BUILDINGS AS b 
				ON OPS.id = b.index_id
			JOIN dbo.FLATS AS f 
				ON b.id = f.bldn_id
			JOIN #t AS o
				ON f.id = o.flat_id
			WHERE OPS.name NOT IN ('SPDU', 'Уралопторг', 'Коммунал.', 'Скороход')
			AND OPS.print_id = 0
			AND (b.index_id = @ops
			OR @ops IS NULL)
			AND (b.tip_id = @tip_id
			OR @tip_id IS NULL)
			GROUP BY OPS.name
			ORDER BY OPS.name
	--****************************************************
	END
	ELSE
	BEGIN
		SELECT
			o.occ
		   ,o.flat_id
		   ,COALESCE(o.kol_people, 0) AS kol_people
		   ,o.PROPTYPE_ID
		   ,o.PaidAll
		   ,o.TOTAL_SQ
		INTO #t2
		FROM dbo.Occupations AS o 
		JOIN dbo.VOcc_Suppliers AS i 
			ON o.occ = i.occ
		WHERE 
			o.STATUS_ID <> 'закр'
			--AND o.TOTAL_SQ > 0
			AND o.occ NOT IN (SELECT
					onp.occ
				FROM dbo.OCC_NOT_print AS onp )
			AND i.fin_id = @fin_id
			AND i.Whole_payment > COALESCE(@sum_dolg, -99999)
			AND (@group_id IS NULL
			OR (@group_id IS NOT NULL
			AND EXISTS (SELECT
					*
				FROM dbo.PRINT_OCC AS po
				WHERE po.occ = o.occ
				AND po.group_id = @group_id)
			))
			AND i.sup_id = COALESCE(@sup_id, i.sup_id)
		--******************************************************
		IF @people0_block = 1
			DELETE FROM #t
			WHERE kol_people = 0

		-- Убираем печать где нет начислений
		IF @paidAll0_block = 1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll = 0 OR t.TOTAL_SQ = 0

		-- Убираем печать где ЕСТЬ начисления
		IF @paid_block=1
			DELETE t
				FROM #t AS t
			WHERE t.PaidAll > 0

		-- Убираем печать где тип собственности не тот
		IF COALESCE(@PROPTYPE_STR, '') <> ''
			DELETE t
				FROM #t AS t
			WHERE NOT EXISTS (SELECT
						1
					FROM STRING_SPLIT(@PROPTYPE_STR, ',')
					WHERE RTRIM(value) <> ''
					AND value = t.PROPTYPE_ID)
		--****************************************************
		SELECT
			OPS.name AS OPS
		   ,COUNT(o.occ) AS kolocc
		FROM dbo.OPS 
		JOIN dbo.BUILDINGS AS b 
			ON OPS.id = b.index_id
		JOIN dbo.FLATS AS f 
			ON b.id = f.bldn_id
		JOIN #t2 AS o
			ON f.id = o.flat_id
			AND (b.index_id = @ops
			OR @ops IS NULL)
			AND (b.tip_id = @tip_id
			OR @tip_id IS NULL)
		GROUP BY OPS.name
		ORDER BY OPS.name
	END

END
go

