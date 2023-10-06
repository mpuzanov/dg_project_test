CREATE   FUNCTION [dbo].[Fun_GetService_idFromSchet](@Schet1 int )  
RETURNS VARCHAR(10)  AS  
BEGIN
--
-- Возвращаем код услуги(например: 'пгаз') по заданному лицевому
-- если по этой услуге разрешено отдельно платить
-- 
  declare @res VARCHAR(10), @service_kod1 tinyint, @occ2 int, @service_id1 VARCHAR(10)

  set @res=null
  
  if @Schet1<=9999999 GOTO LABEL_END -- 6,7 значный код не обрабатываем

--  if (@Schet1>999999) and (@Schet1<=9999999) -- 7 значный код
--  begin
--    select @service_kod1=@Schet1/1000000
--    select @occ2=@Schet1%1000000
--  end
  if (@Schet1>9999999) -- 8 значный код
  begin
    select @service_kod1=@Schet1/10000000
    select @occ2=(@Schet1%10000000)/10
  end


  select @service_id1=id from dbo.SERVICES where service_kod=@service_kod1


  if exists(select * from dbo.consmodes_list
            where occ=@occ2 and service_id=@service_id1 
                  and (is_counter>0 or account_one=1) )
  begin  -- если по этой услуге разрешено отдельно платить
       set @res=@service_id1
  end


LABEL_END:
  return @res
END
go

