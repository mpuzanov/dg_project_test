-- =============================================
-- Author:		Name
-- Create date: 
-- Description:	Выдает главные поля заданного фин.периода
-- =============================================
CREATE        FUNCTION [dbo].[fun_calendar]
(
	  @fin_id1 SMALLINT
)
RETURNS TABLE
/*
select * from [dbo].[Fun_Calendar](250)
*/
AS
RETURN (
	SELECT cp.fin_id
		 , StrFinPeriod
		 , cast(start_date AS DATE) AS start_date
		 , cast(end_date AS DATE) AS end_date
	FROM dbo.Calendar_period cp
	WHERE fin_id = @fin_id1
)
go

