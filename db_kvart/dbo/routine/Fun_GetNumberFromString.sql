-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetNumberFromString]
(
	  @Input VARCHAR(4000)
	, @MinNumberLength INT
)
RETURNS @returntable TABLE
(
	val BIGINT
)
BEGIN
/*
SELECT val FROM dbo.Fun_GetNumberFromString('ЛС=1089048/Г.ИЖЕВСК, УЛ. КРАСНОГЕРОЙСКАЯ, Д.89, КВ.48/БЕЗ НДС/СИСТЕМА"ГОРОД" FSG.RU//216810451//1 560298041', 5)

;WITH cte AS (
SELECT dbo.Fun_GetFalseOccIn(val) as val 
FROM dbo.Fun_GetNumberFromString('ЛС=1089048/Г.ИЖЕВСК, УЛ. КРАСНОГЕРОЙСКАЯ, Д.89, КВ.48/БЕЗ НДС/СИСТЕМА"ГОРОД" FSG.RU//216810451//1 560298041', 5)
)
SELECT t.val, o.occ, t_sup.occ, t_sup.sup_id
From cte as t
LEFT JOIN dbo.Occupations as o ON o.Occ=t.val
OUTER APPLY (SELECT TOP (1) os.occ, os.sup_id FROM dbo.Occ_Suppliers as os WHERE os.occ_sup=t.val) as t_sup
WHERE o.occ IS NOT NULL
OR t_sup.occ IS NOT NULL

*/
	DECLARE @StartIndex INT = PATINDEX('%[0-9]%', @Input)
		  , @EndIndex INT = 0
		  , @PadLength INT
		  , @TotalPadLength INT = 0;
	WHILE @StartIndex <> 0
	BEGIN
		SET @StartIndex = @StartIndex + @EndIndex;
		SET @EndIndex = @StartIndex;

		WHILE PATINDEX('[0-9]', SUBSTRING(@Input, @EndIndex, 1)) = 1
			SET @EndIndex = @EndIndex + 1;
		
		SET @PadLength = (@EndIndex - @StartIndex);
		
		IF @PadLength>=@MinNumberLength
			INSERT @returntable (val) VALUES(CAST(SUBSTRING(@Input, @StartIndex, @PadLength) AS BIGINT))		

		SET @EndIndex = @EndIndex - 1;
		SET @StartIndex = PATINDEX('%[0-9]%', RIGHT(@Input, LEN(@Input) - @EndIndex));
	END;
	
	RETURN 
END
go

