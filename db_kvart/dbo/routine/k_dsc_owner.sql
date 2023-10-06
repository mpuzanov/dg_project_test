CREATE   PROCEDURE [dbo].[k_dsc_owner](@owner1 INT
)
AS
    --
-- Показываем список льгот у человека
--
    SET NOCOUNT ON
    SET LANGUAGE RUSSIAN

SELECT           CASE
                     WHEN active = 1 THEN 'Да'
                     ELSE 'Нет'
                     END as ActiveStr,
                 ow.id,
                 owner_id,
                 dscgroup_id,
                 active,
                 issued,
                 issued2,
                 expire_date,
                 doc,
    DelDateLgota=dbo.Fun_GetOnlyDate(DelDateLgota),
    --expire_del=dbo.Fun_GetOnlyDate(expire_del),
                 USER_ID,
    'User_Name'=dbo.Fun_GetFIOUser(ow.user_id),
                 ds.name,
    expire=      CASE
                     WHEN DATEPART(YEAR, expire_date) = 2050 THEN 'постоянно'
                     ELSE DATENAME(MONTH, expire_date) + ' ' + DATENAME(YEAR, expire_date)
                     END
        ,
                 doc_no,
                 doc_seria,
                 doc_org
FROM dsc_owners AS ow 
         JOIN dsc_groups AS ds ON ow.dscgroup_id = ds.id
         JOIN dbo.Fun_SpisokLgotaActive(@owner1) AS ow2 ON ow.id = ow2.id1
WHERE ow.owner_id = @owner1
ORDER BY active DESC
go

