-- Batch submitted through debugger: SQLQuery11.sql|5|0|C:\Documents and Settings\manager\Local Settings\Temp\~vs84.sql
-- =============================================
-- Author:		Пузанов
-- Create date: 22.01.2008
-- Description:	Для лучшего платильщика определяем банк где платит  (если только в 1)
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetBankOplata]
(
	@occ1	INT
	,@year	SMALLINT
)
RETURNS VARCHAR(15)
/*
select dbo.Fun_GetBankOplata(680001163,2016)
select dbo.Fun_GetBankOplata(680000097,2016)
*/
AS
BEGIN

	DECLARE	@ResultVar	VARCHAR(30)=''
			,@kol		SMALLINT

		SELECT TOP(1)
			@ResultVar=SUBSTRING(b.short_name, 1, 30)
			,  @kol=COUNT(b.short_name) over() 
		FROM dbo.Payings AS p 
		JOIN dbo.Paydoc_packs AS pd 
			ON p.pack_id = pd.id
		JOIN dbo.Paycoll_orgs po 
			ON pd.source_id = po.id
			AND pd.fin_id = po.fin_id
		JOIN dbo.bank AS b 
			ON po.bank = b.id
		WHERE p.occ = @occ1
		AND YEAR(pd.day) = @year
		GROUP BY b.short_name

	IF @kol > 1
		SELECT
			@ResultVar = ''

	RETURN @ResultVar

END
go

