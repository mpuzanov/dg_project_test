CREATE   PROCEDURE [dbo].[k_intPrint_sum_sup]
( @fin_id1 SMALLINT, -- Фин.период
  @occ1 INT,  -- лицевой
  @sup_id INT = 0
)
AS
/*

Выдаем итоговые значения сумм по услугам для 
Единой квитанции

*/

SET NOCOUNT ON

IF @sup_id is null set @sup_id=0

SELECT 	
   SUM(p.saldo) AS 'saldo'
   ,SUM(p.value) AS 'value'
   ,SUM(p.added) AS 'added'
   ,SUM(p.paid) AS 'paid'
   ,SUM(p.debt) AS 'debt'
 FROM dbo.View_paym AS p
 JOIN dbo.View_services AS s ON p.service_id=s.id
 WHERE p.fin_id=@fin_id1
      AND (p.occ=@occ1) 
      AND (p.subsid_only=0)
      AND (p.sup_id=@sup_id)
go

