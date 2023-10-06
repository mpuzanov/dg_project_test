CREATE   PROCEDURE [dbo].[k_MaxLgota] 
( @owner_id1 int
)
AS
set nocount on
 
select top 1 dscgroup_id
from dbo.dsc_owners
where owner_id=@owner_id1 and active=1
go

