CREATE   PROCEDURE [dbo].[k_show_people2](
    @owner_id1 INT
)
AS
/* 
Показываем историяю проживания человека в Картотечнике
*/

SET NOCOUNT ON

SELECT p.id as owner_id
     , P.people_uid
     , KraiOld
     , RaionOld
     , TownOld
     , VillageOld
     , StreetOld
     , Nom_domOld
     , Nom_kvrOld
     , KraiNew
     , RaionNew
     , TownNew
     , VillageNew
     , StreetNew
     , Nom_domNew
     , Nom_kvrNew
     , KraiBirth
     , RaionBirth
     , TownBirth
     , VillageBirth
FROM People_2 as p2
     JOIN People P on p2.owner_id= P.id
WHERE p.id = @owner_id1
go

