CREATE   PROCEDURE [dbo].[adm_operations](
    @group_id1 VARCHAR(10)
)
AS
/*
    Список доступных операций в заданной группе
*/
    SET NOCOUNT ON

SELECT g.*
     , o.name
FROM dbo.Group_authorities AS g
         JOIN dbo.Operations AS o ON g.op_id = o.op_id
WHERE g.group_id = @group_id1
ORDER BY o.op_no
go

