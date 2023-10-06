-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[ws_show_counters_value]
(
	@occ		INT
   ,@counter_id INT = NULL
   ,@row1		INT = 6	  -- кол-во последних показаний по ПУ
)
AS
/*
exec ws_show_counters_value @occ=33100
exec ws_show_counters_value @occ=350033100, @counter_id=65670, @row1=10
*/
BEGIN
	SET NOCOUNT ON;

	IF @row1 IS NULL
		SET @row1 = 6

	DECLARE @fin_current SMALLINT
		   ,@tip_id		 SMALLINT

	SELECT
		@fin_current = o.fin_id
	   ,@tip_id = o.tip_id
	FROM dbo.Occupations o 
	WHERE o.occ = @occ

	IF @fin_current IS NULL
		SELECT
			@occ = o.occ
		   ,@fin_current = o.fin_id
		   ,@tip_id = o.tip_id
		FROM dbo.Occ_Suppliers os 
		JOIN dbo.Occupations AS o 
			ON os.occ=o.occ 
			AND os.fin_id=o.fin_id
		WHERE os.occ_sup = @occ
	IF @@rowcount = 0
	BEGIN
		SELECT
			@occ = dbo.Fun_GetFalseOccIn(@occ)
		SELECT
			@fin_current = o.fin_id
		   ,@tip_id = o.tip_id
		FROM dbo.Occupations o 
		WHERE o.occ = @occ
	END

	SELECT
		occ
	   ,counter_id
	   ,CAST(inspector_date AS DATE) AS inspector_date
	   ,inspector_value
	   ,actual_value
	   ,fin_str
	   ,id
	   ,serial_number
	   ,serv_name
	   ,fin_id
	FROM (SELECT
			c.occ
		   ,ci.counter_id
		   ,ci.inspector_date
		   ,ci.inspector_value
		   ,ci.actual_value
		   ,cp.StrFinPeriod as fin_str
		   ,ci.fin_id
		   ,ci.id
		   ,c.serial_number
		   ,s.name as serv_name
		   ,DENSE_RANK() OVER (PARTITION BY ci.counter_id ORDER BY ci.inspector_date DESC) AS toprank
		FROM dbo.Counter_inspector ci
		JOIN dbo.View_counter_all_lite AS c
			ON ci.counter_id = c.counter_id
		JOIN dbo.Services as s
			ON c.service_id=s.id
		JOIN dbo.Calendar_period as cp 
			ON c.fin_id=cp.fin_id
		WHERE c.occ = @occ
		AND c.fin_id=@fin_current
		AND (c.counter_id = @counter_id
		OR @counter_id IS NULL)
		AND c.date_del IS NULL) AS t
	WHERE toprank <= @row1

END
go

