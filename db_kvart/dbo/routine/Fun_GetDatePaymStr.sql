CREATE   FUNCTION [dbo].[Fun_GetDatePaymStr]
(
	@occ1		INT
	,@fin_id1	SMALLINT
	,@sup_id	INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*
	Выдаем строку с датами платежей по лицевому  и фин. периоду
	для оборотно-сальдовой ведомости по лицевым
	
	select dbo.Fun_GetDatePaymStr(680001703, 166, 323)
	
	*/
	DECLARE @Str1 VARCHAR(50) = ''

	SELECT
		@Str1 = SUBSTRING((SELECT
				CONCAT(',' , LTRIM(CONVERT(VARCHAR(10), p2.day, 4)))
			FROM dbo.PAYINGS AS p1
			JOIN dbo.PAYDOC_PACKS AS p2
				ON p1.pack_id = p2.id
			WHERE p1.occ = @occ1
			AND p2.fin_id = @fin_id1
			AND p1.sup_id =
				CASE
					WHEN @sup_id IS NOT NULL THEN @sup_id
					ELSE 0
				END
			GROUP BY p2.day
			FOR XML PATH (''))
		, 2, 50)

	RETURN COALESCE(@Str1, '')

END
go

