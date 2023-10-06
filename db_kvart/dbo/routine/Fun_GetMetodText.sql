-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetMetodText]
(
	  @metod SMALLINT
)
/*
select dbo.Fun_GetMetodText(p.metod) AS metod
select dbo.Fun_GetMetodText(999) AS metod999
	,dbo.Fun_GetMetodText(0) AS metod0
	,dbo.Fun_GetMetodText(8) AS metod8
	,dbo.Fun_GetMetodText(null) AS metodNull
*/
RETURNS VARCHAR(15)
WITH SCHEMABINDING
AS
BEGIN

	RETURN CAST(
	CASE @metod
		WHEN 0 THEN 'не начислять'
		WHEN 1 THEN 'по норме'
		WHEN 2 THEN 'по среднему'
		WHEN 3 THEN 'по счетчику'
		WHEN 4 THEN 'по домовому'
		--5 - на основании другой услуги, 6 - не брать в расчет ППУ, 7 - начислять на 1 в своб л/сч)
		WHEN 8 THEN 'ручной'
		WHEN 9 THEN 'по среднему'
		ELSE NULL
	END AS VARCHAR(15))

END
go

