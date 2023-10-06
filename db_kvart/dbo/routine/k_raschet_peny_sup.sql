CREATE   PROCEDURE [dbo].[k_raschet_peny_sup]
(
	  @occ_sup INT -- лицевой поставщика
	, @fin_id1 SMALLINT
	, @debug BIT = 0
)
AS
	/*
	
	Перерасчет пени по заданному лицевому поставщика
	
	автор: Пузанов
	
	k_raschet_peny_sup
	
	*/

	SET NOCOUNT ON

	EXEC k_raschet_peny_sup_new @occ_sup = @occ_sup
							  , @fin_id1 = @fin_id1
							  , @debug = @debug
	RETURN
go

