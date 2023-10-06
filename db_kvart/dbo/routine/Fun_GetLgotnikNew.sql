-- =============================================
-- Author:		Пузанов 
-- Create date: 20/02/08
-- Description:	возвращает 1 если льготы не было в прошлом месяце
-- =============================================
CREATE FUNCTION [dbo].[Fun_GetLgotnikNew]
(
	@fin_id smallint, @occ int, @owner_id int
)
RETURNS bit
AS
BEGIN
	
	DECLARE @ResultVar bit, @fin_old smallint
	set @ResultVar=0
    set @fin_old=@fin_id-1

    if not exists(
	SELECT top 1 owner_id
    FROM PEOPLE_HISTORY 
    where occ=@occ
    and fin_id=@fin_old 
	and owner_id=@owner_id
    and lgota_id>0
	)
    set @ResultVar=1
	
	RETURN @ResultVar

END
go

