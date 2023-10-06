CREATE   FUNCTION [dbo].[Fun_GetFalseOccIn]
(
    @occ1    INT
)
RETURNS INT
AS
/*
Вырезаем лицевой из подставного лицевого счета
select dbo.Fun_GetFalseOccIn(291769)
select dbo.Fun_GetFalseOccIn(560291769)
select dbo.Fun_GetFalseOccIn(560358751)

*/
BEGIN
	IF NOT EXISTS(SELECT 1 FROM dbo.Occupations o WHERE occ=@occ1)
	BEGIN	
		DECLARE @strschtl VARCHAR(9),
				@kod      VARCHAR(3)    = '',
				@res_occ  INT           = 0

		SELECT @strschtl=STR(@occ1,9)
		SELECT @kod=LEFT(@strschtl,3)
		IF EXISTS(SELECT 1 FROM dbo.Occupation_types ot WHERE occ_prefix_tip=@kod AND occ_prefix_tip<>'')
		BEGIN
			SELECT @strschtl = RIGHT(@strschtl,6)
			SELECT @occ1 = CAST(@strschtl AS INT)
		END  
	END
	
	RETURN @occ1

END
go

