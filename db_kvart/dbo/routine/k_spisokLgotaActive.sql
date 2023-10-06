CREATE   PROCEDURE [dbo].[k_spisokLgotaActive] 
( @owner_id1 INT
)
AS
--
--  Выдаем список возможных активных льгот у человека
--
SET NOCOUNT ON

DECLARE @fin_id SMALLINT

SELECT @fin_id=o.fin_id  -- тек.фин.период лицевого счёта
FROM dbo.PEOPLE AS p 
JOIN dbo.OCCUPATIONS AS o ON p.occ=o.occ
WHERE p.id=@owner_id1

DECLARE @start_date SMALLDATETIME
SELECT @start_date=start_date FROM dbo.GLOBAL_VALUES  WHERE fin_id=@fin_id
 
SELECT id
FROM dbo.dsc_owners 
WHERE owner_id=@owner_id1 
AND expire_date>@start_date 
AND DelDateLgota IS NULL
go

