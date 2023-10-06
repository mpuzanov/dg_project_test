-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2011
-- Description:	Получаем строку документов перерасчётов по лицевому счёту
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAddStrServ](
    @occ1 INT
, @fin_id1 SMALLINT = NULL
, @service_id VARCHAR(10) = NULL
)
    RETURNS VARCHAR(400)
/*
Возврат строки документов с перерасчётами

select [dbo].[Fun_GetAddStrServ](315246,122,null)
select [dbo].[Fun_GetAddStrServ](680001163,139,null)

*/
AS
BEGIN

    DECLARE @StrAdds VARCHAR(400) = ''

    IF @fin_id1 IS NULL
        SET @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

    SELECT @StrAdds = STUFF((SELECT CONCAT(', ' , [doc])
                             FROM [dbo].View_added_lite AS ap
                                      JOIN dbo.Added_Types at ON ap.add_type = at.id
                             WHERE ap.occ = @occ1
                               AND ap.fin_id = @fin_id1
                               AND ap.doc <> ''
                               AND ap.value <> 0
                               AND (ap.service_id = @service_id
                                 OR @service_id IS NULL)
                               AND at.visible_kvit=CAST(1 AS BIT)
                             GROUP BY [doc]
                             FOR XML PATH (''))
        , 1, 2, '')

    IF @StrAdds <> ''
        SET @StrAdds = N'Перерасчёты:' + @StrAdds

    RETURN @StrAdds

END
go

