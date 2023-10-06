-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Расчёт квартплаты в квартире
-- =============================================
CREATE           PROCEDURE [dbo].[k_raschet_flat]
(
	@flat_id INT,
	@debug BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@occ1		INT
			,@fin_id1	INT
			,@er		INT
			,@strerror	VARCHAR(100)


	DECLARE curs CURSOR LOCAL FOR
		SELECT
			occ
			,o.fin_id
		FROM dbo.OCCUPATIONS AS o
		WHERE o.flat_id = @flat_id
		AND status_id <> 'закр'
		--AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
		ORDER BY occ

	OPEN curs
	FETCH NEXT FROM curs INTO @occ1, @fin_id1

	WHILE (@@fetch_status = 0)
	BEGIN
		IF @debug=1 RAISERROR (' %d', 10, 1, @occ1) WITH NOWAIT;

		-- Расчитываем квартплату
		EXEC @er = dbo.k_raschet_2	@occ1
									,@fin_id1
									--,@people_list = 1

		IF @er <> 0
		BEGIN
			SET @strerror = 'Ошибка при перерасчете! Лицевой: ' + STR(@occ1)
			EXEC dbo.k_adderrors_card @strerror
		END

		FETCH NEXT FROM curs INTO @occ1, @fin_id1
	END

	CLOSE curs
	DEALLOCATE curs
END
go

