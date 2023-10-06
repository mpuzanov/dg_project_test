CREATE   PROCEDURE [dbo].[k_edit_OPS]

( @index_id  int
)
AS
--
--  Добавляем или убираем доступ пользователей к определенным программам  
--
set nocount on

update	buildings 
set	index_id=1
where	index_id=@index_id
 
delete	OPS 
where	id=@index_id
go

