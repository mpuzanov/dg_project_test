CREATE   PROCEDURE [dbo].[k_dsc_groups] AS
set nocount on
 
select id, name,name2=str(id,2)+'   '+name from dsc_groups where id>0
go

