-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	кол-во месяцев без подачи показаний
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetKolMonthCounterNo]
(
	@occ1			INT
	,@serv1			VARCHAR(10)	= NULL
	,@fin_current	SMALLINT	= NULL
)
RETURNS SMALLINT
AS
BEGIN
	/*
	select dbo.Fun_GetKolMonthCounterNo(680002934,'хвод',162)
	select dbo.Fun_GetKolMonthCounterNo(680003042,'гвод',NULL)
	select dbo.Fun_GetKolMonthCounterNo(680004390,NULL,NULL)
	select dbo.Fun_GetKolMonthCounterNo(700073800,NULL,NULL)
	*/
	DECLARE	@fin_id1		SMALLINT
			,@date_create	SMALLDATETIME
			,@kol			SMALLINT	= 0
			,@counter_id	INT

	IF @fin_current IS NULL
		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT TOP 1
		@counter_id = counter_id
	FROM dbo.Counter_list_all cla
	JOIN dbo.Counters AS C
		ON cla.counter_id = C.id
	WHERE 1=1
		AND cla.occ = @occ1
		AND C.date_del IS NULL
		AND cla.service_id = COALESCE(@serv1, cla.service_id)

	-- находим последний месяц подачи показаний 
	SELECT TOP 1
		@fin_id1 = ci.fin_id
		,@date_create = C.date_create
	FROM dbo.Counters AS C 
	LEFT JOIN dbo.Counter_inspector ci 
		ON ci.counter_id = C.id
		AND ci.tip_value = 1
	WHERE C.id = @counter_id
	ORDER BY ci.fin_id DESC
	--PRINT @fin_id1

	-- если не было показаний берём месяц создания ИПУ
	IF @fin_id1 IS NULL
		SELECT TOP 1
			@fin_id1 = fin_id
		FROM dbo.Global_values gv 
		WHERE @date_create BETWEEN gv.start_date AND gv.end_date

	--PRINT @fin_id1		
	IF @fin_id1 IS NULL
		SELECT
			@kol = DATEDIFF(MONTH, @date_create, current_timestamp)
	ELSE
	BEGIN
		IF @fin_current < @fin_id1
			SET @fin_id1 = @fin_current
		SELECT
			@kol = @fin_current - @fin_id1
	END

	RETURN @kol

END
go

