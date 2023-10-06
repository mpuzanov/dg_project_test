CREATE   PROCEDURE  [dbo].[k_edit_build_index]

( @build_id int,
  @index_id  int
)
AS
--
--  Добавляем или убираем доступ пользователей к определенным программам  
--
set nocount on
 
update	buildings 
set	index_id=@index_id
where	id=@build_id
go

