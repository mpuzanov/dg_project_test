-- =============================================
-- Author:		Пузанов
-- Create date: 9.04.2010
-- Description:	Возвращаем 
-- Пример вызова:  select * from dbo.Fun_GetDolgMesTableAdd(@t,@fin_id)
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetDolgMesTableAdd]
(
	@inTable	dbo.myTypeTableOcc	READONLY
	,@fin_id	SMALLINT
)
RETURNS @t1 TABLE
(
	occ		INT
	,mes	SMALLINT
)
AS
BEGIN

	--
	DECLARE @start_date SMALLDATETIME
	SELECT
		@start_date = start_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_id

	INSERT
	INTO @t1
	(	occ
		,mes)
		SELECT
			t.occ
			,mes = DATEDIFF(MONTH, MAX(gb.start_date), @start_date) - 1
		FROM dbo.OCC_HISTORY AS oh
		JOIN dbo.GLOBAL_VALUES AS gb
			ON oh.fin_id = gb.fin_id
		JOIN @inTable AS t
			ON oh.occ = t.occ
		WHERE oh.fin_id < @fin_id
		AND oh.value > 0
		GROUP BY t.occ
		ORDER BY t.occ

	RETURN

END
go

