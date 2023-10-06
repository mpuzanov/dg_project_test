CREATE   PROCEDURE [dbo].[k_intPrint_sum]
( @fin_id1 SMALLINT, -- Фин.период
  @occ1 INT  -- лицевой
)
AS
/*

Выдаем итоговые значения сумм по услугам для 
Единой квитанции

*/

SET NOCOUNT ON

           
SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)   -- если на входе был ложный лицевой

 SELECT 	
   SUM(p.saldo) AS saldo
   ,SUM(p.value) AS value
   ,SUM(p.added) AS added
   ,SUM(p.paid) AS paid
   ,SUM(p.debt) AS debt
 FROM dbo.View_PAYM AS p
 WHERE p.fin_id=@fin_id1
      AND (occ=@occ1) 
      AND (p.subsid_only=0)
      AND (p.account_one=0 OR  p.account_one IS NULL)
go

