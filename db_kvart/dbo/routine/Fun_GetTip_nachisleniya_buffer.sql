-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	для ИВЦ для выгрузок в Буфер должны быть стандартные наименования
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetTip_nachisleniya_buffer]
(
@tip_occ smallint
)
RETURNS VARCHAR(30)
AS
BEGIN
	/*
	select dbo.Fun_GetTip_nachisleniya_buffer(1), dbo.Fun_GetTip_nachisleniya_buffer(3)
	dbo.Fun_GetTip_nachisleniya_buffer(sup.tip_occ) AS Tip_nachisleniya
	*/
	RETURN CASE
               WHEN @tip_occ = 3 THEN 'Кап. ремонт'
               ELSE 'ЖКУ'
        END
END
go

