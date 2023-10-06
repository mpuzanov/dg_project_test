CREATE PROCEDURE [dbo].[k_SumPaym]
(  @occ1 int,
   @p1 smallint = 8
/*
  p1=1 - Сальдо
 2 - Соц. норма
 3 - Начислено
 4 - Льгота
 5 - Разовые
 6 - Пеня
 7 - Компенсация
 8 - К оплате
 
*/
)
AS
SET NOCOUNT ON

select 
case @p1
	when 1 then sum(saldo) 
	when 2 then 0
	when 3 then sum(value)
	when 5 then sum(added)

	when 8 then sum(paid)
	else 0
end as sum
from dbo.Paym_list
where occ=@occ1
go

