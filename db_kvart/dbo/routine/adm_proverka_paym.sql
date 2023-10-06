-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Проверка платежей и расчётов по типу фонда
-- =============================================
CREATE   PROCEDURE [dbo].[adm_proverka_paym](
    @tip_id SMALLINT = NULL
, @in_table BIT = 0
)
AS
/*

Не испльзуется

adm_proverka_paym @tip_id=28,@in_table=1
*/
BEGIN
    SET NOCOUNT ON;

    EXEC adm_proverka_paym_fin @tip_id=@tip_id, @in_table=@in_table, @fin_id=NULL

END
go

