CREATE   FUNCTION [dbo].[Fun_GetStart_date]
(
	@fin_id1 SMALLINT
)
RETURNS SMALLDATETIME
AS
BEGIN

	/* 
	Выдаем первую дату заданного финансового периоду
	select [dbo].[Fun_GetStart_date](180)
	*/

	RETURN (SELECT
			start_date
		FROM dbo.GLOBAL_VALUES
		WHERE fin_id = @fin_id1)


END
go

