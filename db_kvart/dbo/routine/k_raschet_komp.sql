CREATE   PROCEDURE [dbo].[k_raschet_komp]
--
--  Процедура расчета компенсации
--
--
-- exec dbo.k_raschet_komp2 56070, 0, 25, 10000, '20040201', '20050301', 2
-- exec dbo.k_raschet_komp2 66769, 0, 49, 0, '20060201', '20060630', 1
/*

declare @SumKomp decimal(9,2)
exec dbo.k_raschet_komp 40000, 0, 54, 0, '20060701', '20061201', 3,@SumKomp OUTPUT,2
select @SumKomp

*/


( @occ1 int,  
  @new1 bit,  
  @fin_id1 smallint,
  @Doxod1 decimal(9,2),   -- Среднемесячный Совокупный доход
  @DateNazn datetime,     -- Дата назначения
  @DateEnd datetime,      -- Дата окончания действия компенсации
  @realy_people1 SMALLINT, -- Кол.человек на которых проводиться расчет компенсации
  @SumKomp decimal(9,2) OUTPUT  -- Расcчитанная сумма компенсации
 ,@metod_id1 SMALLINT = 2  -- метод расчета (2-по стандартам) 
)
--WITH ENCRYPTION
AS
 
SET NOCOUNT ON
 
if dbo.Fun_GetOccClose (@occ1)=0
begin
 raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
 return
end

declare @ExtSubsidia bit, @fin_current smallint
SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

select @ExtSubsidia=ExtSubsidia from GLOBAL_VAlUES where fin_id=@fin_current

-- Если внешний расчет субсидий то выходим из процедуры
if @ExtSubsidia=1
begin
	return
end
go

