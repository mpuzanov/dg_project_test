-- =============================================
-- Author:		Пузанов
-- Create date: 164.11.2021
-- Description:	Получаем строку документов перерасчётов по лицевому счёту с суммой
-- =============================================
CREATE         FUNCTION [dbo].[Fun_GetAddStrSum](
    @occ1 INT
, @fin_id1 SMALLINT = NULL
, @sup_id INT = NULL
, @service_id VARCHAR(10) = NULL
)
    RETURNS VARCHAR(800)
/*
Возврат строки документов с перерасчётами

select dbo.Fun_GetAddStrSum(33009,230,null,null)

*/
AS
BEGIN

    DECLARE @StrAdds VARCHAR(800) = ''

    IF @fin_id1 IS NULL
        SET @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

    SELECT @StrAdds = STUFF((
                            SELECT CONCAT(', ' , [doc] ,': '+LTRIM(STR(SUM(ap.value),9,2))) -- +dbo.FSTR(SUM(ap.value),9,2)
                            FROM dbo.View_added_lite AS ap
                                     JOIN dbo.Added_Types at ON ap.add_type = at.id
                            WHERE ap.occ = @occ1
                              AND ap.fin_id = @fin_id1
                              AND ap.sup_id = COALESCE(@sup_id, 0)
                              AND ap.doc <> ''
                              AND ap.value <> 0
                              AND (@service_id IS NULL OR ap.service_id = @service_id)
                              AND at.visible_kvit = CAST(1 AS BIT)
                            GROUP BY [doc]
                                     --HAVING SUM(ap.VALUE)<>0	 -- общая сумма по документу <>0   Нужно даже если = 0
                            FOR XML PATH ('')
                        ), 1, 1, '')

    IF @StrAdds <> ''
        SET @StrAdds = N'Перерасчёты:' + @StrAdds

    RETURN @StrAdds

END
go

