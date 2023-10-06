-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[ka_peny_vozvrat_added_build]
(
	  @build_id1 INT
	, @fin_id1 SMALLINT
	, @fin_id2 SMALLINT
	, @sup_id1 INT = NULL
	, @is_plus_peny BIT = 1
	, @debug BIT = 0
)
AS
/*
Возврат начисленных пени за период

EXEC ka_peny_vozvrat_added_build @build_id1=6810, @fin_id1=232, @fin_id2=232, @sup_id1=345, @is_plus_peny = null ,@debug=1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @occ1 INT		  

	SET @is_plus_peny = COALESCE(@is_plus_peny, 1)

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	
	DECLARE curs CURSOR LOCAL FOR
		SELECT occ
		FROM dbo.Occupations as o
			JOIN dbo.Flats as f ON 
				o.flat_id=f.id
		WHERE f.bldn_id=@build_id1
	OPEN curs
	FETCH NEXT FROM curs INTO @occ1
	WHILE (@@fetch_status = 0)
	BEGIN
		EXEC k_peny_vozvrat_added @occ1=@occ1,
			@fin_id1=@fin_id1,
			@fin_id2=@fin_id2,
			@sup_id1=@sup_id1, 
			@is_plus_peny = @is_plus_peny ,
			@debug=@debug

		FETCH NEXT FROM curs INTO @occ1
	END
	CLOSE curs;
	DEALLOCATE curs;


END
go

