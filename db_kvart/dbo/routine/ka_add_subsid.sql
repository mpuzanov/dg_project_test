CREATE   PROCEDURE [dbo].[ka_add_subsid] 
( @occ1 int,
  @service_id1 VARCHAR(10),
  @summa1 money,
  @doc1 varchar(50)=null,
  @dsc_owner_id1 int = null -- код получателя субсидии
)
AS
--
--  Ввод разовых по субсидиям тип 4
--
if dbo.Fun_AccessAddLic(@occ1)=0
begin
   raiserror('Для Вас работа с Разовыми запрещена',16,1)
   return
end
 
if dbo.Fun_GetRejim()<>'норм'
begin
   raiserror('База закрыта для редактирования!',16,1)
   return
end
 
if dbo.Fun_AccessEditLic(@occ1)=0
begin
   raiserror('Изменения запрещены!',16,1)
   return
end
 
set nocount on
 
declare @add_type1 smallint, @id1 int
set @add_type1=4
 
set @id1=0
select @id1=id  from added_payments 
where occ=@occ1 and service_id=@service_id1 and add_type=@add_type1
 
declare @user_edit1 smallint
select @user_edit1=id from users  where login=SYSTEM_USER

-- Если разовые по этой услуге с типом 4 есть то
if @id1<>0
begin
    update added_payments 
    set value=@summa1,
        user_edit=@user_edit1,
        dsc_owner_id=@dsc_owner_id1
    where id=@id1
end
else
begin
   if @summa1<>0
   begin
      insert into added_payments(occ, service_id, add_type, 
      value, doc, user_edit, dsc_owner_id)
      values(@occ1,
	  @service_id1,
	  @add_type1,
	  @summa1,
	  @doc1,
          @user_edit1,
          @dsc_owner_id1)
   end
end

 -- сохраняем в историю изменений
   exec  k_write_log @occ1, 'раз!'
go

