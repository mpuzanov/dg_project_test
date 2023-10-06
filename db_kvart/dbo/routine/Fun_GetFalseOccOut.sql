CREATE   FUNCTION [dbo].[Fun_GetFalseOccOut]
(
	@occ1	 INT
   ,@tip_id1 SMALLINT
)
RETURNS INT
AS
/*
Получение подставного лицевого счета для Платёжного документа если он настроен

select dbo.Fun_GetFalseOccOut(234678,60)
select dbo.Fun_GetFalseOccOut(234678,50)
select dbo.Fun_GetFalseOccOut(234678,1)

*/
BEGIN
	DECLARE @strschtl		VARCHAR(9) = LTRIM(STR(@occ1,9))
		   ,@occ_prefix_tip VARCHAR(3) = ''
	
	IF LEN(@strschtl)=9  -- если длинна заданного лицевого 9 знаков - префикс не добавляем
		RETURN @occ1

	SELECT @occ_prefix_tip=occ_prefix_tip FROM dbo.OCCUPATION_TYPES ot WHERE id=@tip_id1

	IF @occ_prefix_tip<>''
	BEGIN
		SET @strschtl = CONCAT(@occ_prefix_tip, RIGHT('000000'+ CAST(@occ1 AS VARCHAR), 6))
		SELECT
			@occ1 = CAST(@strschtl AS INT)
	END

	RETURN @occ1

END
go

