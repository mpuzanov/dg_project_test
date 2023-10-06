-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Расчёт квартплаты по дому
-- =============================================
CREATE           PROCEDURE [dbo].[k_raschet_build]
(
	@build_id	INT
	,@debug		BIT	= 0
	,@is_calc_ipu BIT = 1
)
AS
/*
07/05/21 - добавил расчет по ИПУ

exec k_raschet_build @build_id=6785, @debug=1
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@occ1		INT
			,@flat_id1	INT
			,@fin_id1	INT
			,@er		INT
			,@strerror	VARCHAR(100)


	DECLARE curs CURSOR LOCAL FOR
		SELECT
			occ
			,flat_id
			,b.fin_current
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats f 
			ON F.id = o.flat_id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id=b.id
		WHERE F.bldn_id = @build_id
		AND o.status_id <> N'закр'
		--AND ot.state_id = 'норм' -- где тип фонда открыт для редактирования
		ORDER BY occ

	OPEN curs
	FETCH NEXT FROM curs INTO @occ1, @flat_id1, @fin_id1

	WHILE (@@fetch_status = 0)
	BEGIN
		IF @debug = 1
			RAISERROR (' %d %d', 10, 1, @occ1, @flat_id1) WITH NOWAIT;

		-- рассчет по ИПУ в квартире
		if @is_calc_ipu=1
		BEGIN
			EXEC  @er = k_counter_raschet_flats2 @flat_id1=@flat_id1, @tip_value1=1, @debug=0, @isRasHistory=0
			IF @er <> 0
			BEGIN
				SET @strerror = N'Ошибка в <k_raschet_build>. Код квартиры: ' + STR(@flat_id1)
				EXEC dbo.k_adderrors_card @strerror
			END
		END

		-- Расчитываем квартплату
		EXEC @er = dbo.k_raschet_2	@occ1
									,@fin_id1
									--,@people_list = 1
		IF @er <> 0
		BEGIN
			SET @strerror = N'Ошибка в <k_raschet_build>. Лицевой: ' + STR(@occ1)
			EXEC dbo.k_adderrors_card @strerror
		END

		FETCH NEXT FROM curs INTO @occ1, @flat_id1, @fin_id1
	END

	CLOSE curs
	DEALLOCATE curs
END
go

