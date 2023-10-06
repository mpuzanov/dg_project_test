CREATE   PROCEDURE [dbo].[k_paydoc_log]
( @pack_id1 int 
)
AS
--
--  заносим историю изменений заданной пачки
--
set nocount on
 
declare @user_id1 smallint
 
select @user_id1=id from users where login=SYSTEM_USER
 
UPDATE PAYDOC_PACKS 
set 
   user_edit=@user_id1,
   date_edit=cast(CURRENT_TIMESTAMP as date)
where id=@pack_id1
go

