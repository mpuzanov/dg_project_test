CREATE   PROCEDURE [dbo].[k_raschet_peny2]
(@occ1 INT
,@debug BIT = 0
,@fin_id1 SMALLINT = NULL -- 
)
AS
/*

Перерасчет пени по заданному лицевому

автор: Пузанов
*/

SET NOCOUNT ON

EXEC k_raschet_peny @occ1=@occ1,@debug=@debug,@fin_id1=@fin_id1
RETURN
--***********************************************************************************
go

