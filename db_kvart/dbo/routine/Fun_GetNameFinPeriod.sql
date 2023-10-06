CREATE   FUNCTION [dbo].[Fun_GetNameFinPeriod]
(
	@fin_id1 SMALLINT
)
RETURNS VARCHAR(15)
AS
BEGIN

	-- Выдаем название заданного финансового периода

	RETURN COALESCE((SELECT
			StrMes
		FROM dbo.GLOBAL_VALUES 
		WHERE fin_id = @fin_id1)
	, '')


END
go

exec sp_addextendedproperty 'MS_Description', N'Выдаем название заданного финансового периода', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetNameFinPeriod'
go

