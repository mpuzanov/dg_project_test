CREATE   FUNCTION [dbo].[Fun_GetDateVidPaymStr](
    @occ1 INT
, @fin_id1 SMALLINT
, @sup_id INT
)
    RETURNS VARCHAR(50)
AS
BEGIN
    /*
    Выдаем строку Банк(Вид платежа)
    
    select [dbo].[Fun_GetDateVidPaymStr](680001703,171,323)
    
    */
    RETURN COALESCE(SUBSTRING((SELECT CONCAT(',', RTRIM(p.source_name), '(', RTRIM(tip_paym), ')')
                               FROM dbo.View_payings AS p
                               WHERE p.occ = @occ1
                                 AND p.fin_id = @fin_id1
                                 AND p.sup_id =
                                     CASE
                                         WHEN @sup_id IS NOT NULL THEN @sup_id
                                         ELSE 0
                                         END
                               GROUP BY p.source_name
                                      , tip_paym
                               FOR XML PATH ('')), 2, 50), '')

END
go

