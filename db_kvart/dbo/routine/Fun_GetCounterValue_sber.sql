-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetCounterValue_sber]
(
	@fin_id SMALLINT
   ,@occ	INT		 = NULL
   ,@sup_id INT		 = NULL
   ,@debug  BIT		 = 0
   ,@p1		SMALLINT = 1 -- 1-строка в файл задолженности, 2-строка в ДШК
)
RETURNS VARCHAR(2000)
AS
BEGIN
/*
select dbo.Fun_GetCounterValue_sber(189,680000033,null,0,1)
select dbo.Fun_GetCounterValue_sber(189,680000033,null,0,2)

*/
	DECLARE @res VARCHAR(2000)

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
		@res =
		STUFF((SELECT
				CASE
					WHEN @p1 = 1 THEN 
						CONCAT(';' , serv_name , '-' , serial_number , ';' , inspector_value)
					WHEN @p1 = 2 THEN 
						CONCAT('|CounterName_' , LTRIM(STR(t.row_num)) , '=' , serv_name , ' ' , serial_number , '|CounterValPre_' , LTRIM(STR(t.row_num)) , '=' , inspector_value)
					ELSE ''
				END
			FROM cte AS t
			ORDER BY serv_name
			FOR XML PATH (''))
		, 1, 1, '')

	RETURN @res

END
go

