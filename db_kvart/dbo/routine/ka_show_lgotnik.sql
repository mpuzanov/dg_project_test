CREATE   PROCEDURE  [dbo].[ka_show_lgotnik]
( @occ1 int
)
AS
--
--  Показываем льготников на лицевом счете
--
/*

Изменил 15.08.07
Берем людей из истории 

*/
SET NOCOUNT ON

 select distinct 
   do.id, 
   dbo.Fun_InitialsPeople(p.owner_id) as Initials, 
   dscgroup_id
 from dbo.PEOPLE_HISTORY as p
	JOIN  DSC_OWNERS as do  ON do.owner_id=p.owner_id
 where p.occ=@occ1
go

