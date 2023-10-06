-- =============================================
-- Author:		Пузанов
-- Create date: 26.01.07
-- Description:	Добавление внешних субсидий по услугам
-- =============================================
CREATE   PROCEDURE [dbo].[k_komp_insert_serv]
@occ1 int,
@service_id1 VARCHAR(10),
@summa_paid1 decimal(9,2)=0,
@summa1 decimal(9,2)=0,
@count_add SMALLINT=0 OUTPUT  -- Если 1 то добавили запись
AS
BEGIN
	SET NOCOUNT ON;

	declare @fin_current smallint
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	select @count_add=0

	if exists(select * from dbo.GLOBAL_VALUES where fin_id=@fin_current and ExtSubsidia=0)
	begin
		print 'Субсидии расчитываються в программе расчета квартплаты'
		-- импорт отменен
		return @count_add
	end

	if not exists(select * from dbo.OCCUPATIONS where occ=@occ1)
	begin
		print 'Лицевой счет не найден'
		-- импорт отменен
		return @count_add
	end

	if not exists(select * from dbo.COMPENSAC_ALL where occ=@occ1 and fin_id=@fin_current)
	begin
		RETURN
	end

	if exists(select * from dbo.COMP_SERV_ALL where occ=@occ1 and service_id=@service_id1 and fin_id=@fin_current)
	begin
		--print 'Обновляем субсидию'
		UPDATE dbo.COMP_SERV_ALL
		SET value_paid=@summa_paid1,
            value_subs=@summa1
		where occ=@occ1 
		 and service_id=@service_id1
		 and fin_id=@fin_current
	end
	else
	begin
		--print 'Добавляем субсидию'
		INSERT INTO dbo.COMP_SERV_ALL
		(fin_id, occ, service_id, tarif, value_socn, value_paid, value_subs)
		VALUES(@fin_current, @occ1, @service_id1, 0, 0, @summa_paid1, @summa1)
	end

select @count_add=1

return @count_add

END
go

