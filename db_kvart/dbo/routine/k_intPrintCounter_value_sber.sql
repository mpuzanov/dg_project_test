-- =============================================
-- Author:		Пузанов
-- Create date: 14.08.2017
-- Description:	Выдаем показания квартиросъемщика по счетчикам на заданном лицевом счете для ГИС ЖКХ в платёжный документ
-- =============================================
CREATE     PROCEDURE [dbo].[k_intPrintCounter_value_sber]
	@fin_id SMALLINT
   ,@occ	INT		 = NULL
   ,@sup_id INT		 = NULL
   ,@debug  BIT		 = 0
   ,@p1		SMALLINT = 1 -- 1-строка в файл задолженности, 2-строка в ДШК
AS
/*
EXEC k_intPrintCounter_value_sber @fin_id=188, @occ= 680004146,@sup_id=323, @debug=1, @p1=1
EXEC k_intPrintCounter_value_sber @fin_id=189, @occ=680000033, @p1=1
EXEC k_intPrintCounter_value_sber @fin_id=189, @occ=680000033, @p1=2
*/
BEGIN
	SET NOCOUNT ON;

	IF @occ IS NULL
		SELECT
			@occ = 0

	IF @p1 IS NULL
		SET @p1 = 1

		;
	WITH cte
	AS
	(SELECT
			CASE
				WHEN C.service_id IN ('хвод', 'хвс2') THEN 'ХВС'
				WHEN C.service_id IN ('гвод', 'гвс2') THEN 'ГВС'
				WHEN C.service_id IN ('элек', 'эле2') THEN 'Э/Э'
				WHEN C.service_id IN ('отоп', 'ото2') THEN 'Отопл'
				ELSE SUBSTRING(C.service_id, 1, 10)
			END AS serv_name
		   ,C.serial_number
		   ,ci2.inspector_value
		   ,ROW_NUMBER() OVER (ORDER BY C.service_id) AS row_num
		FROM dbo.COUNTERS C 
		JOIN dbo.COUNTER_LIST_ALL AS cl 
			ON C.id = cl.counter_id
		CROSS APPLY (SELECT TOP 1
				ci.inspector_value
			FROM dbo.COUNTER_INSPECTOR AS ci 
			WHERE cl.counter_id = ci.counter_id
			AND cl.fin_id = ci.fin_id
			ORDER BY ci.inspector_date DESC) AS ci2
		WHERE (cl.occ = @occ
		OR @occ IS NULL)
		AND cl.fin_id = @fin_id)
	--IF @debug=1 SELECT * FROM cte
	SELECT
		STUFF((SELECT
				CASE
					WHEN @p1 = 1 THEN ';' + serv_name + '-' + serial_number + ';' + LTRIM(STR(inspector_value))
					WHEN @p1 = 2 THEN '|CounterName_' + LTRIM(STR(t.row_num)) + '=' + serv_name + ' ' + serial_number + '|CounterValPre_' + LTRIM(STR(t.row_num)) + '=' + LTRIM(STR(inspector_value))
					ELSE ''
				END
			FROM cte AS t
			ORDER BY serv_name
			FOR XML PATH (''))
		, 1, 1, '')
		AS inspector_value_str


END
go

