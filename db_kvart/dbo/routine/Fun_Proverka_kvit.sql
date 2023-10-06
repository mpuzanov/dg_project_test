-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_Proverka_kvit]
(
	  @fin_id1 SMALLINT
	, @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @occ1 INT = NULL
)
RETURNS TABLE
/*
DECLARE @fin_id1 SMALLINT = 236
	  , @tip_id1 SMALLINT = 4
	  , @build_id1 INT = NULL
	  , @occ1 INT = 910003452

IF EXISTS (
		SELECT *
		FROM dbo.Fun_Proverka_kvit(@fin_id1, @tip_id1, @build_id1, @occ1)
	)
	PRINT '! надо обновлять квитанции :('
ELSE
	PRINT 'обновлять квитанции не надо :)'
*/
AS
	RETURN
	(
	SELECT o.Occ
		 , o.Whole_payment
		 , i.SumPaym
		 , i.Penalty_value
		 , (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) AS Penalty_value_o
	FROM dbo.View_occ_all_lite  AS o 
		LEFT JOIN dbo.Intprint AS i ON o.Occ = i.Occ
			AND o.fin_id = i.fin_id
		JOIN dbo.VOcc_types AS ot ON o.tip_id = ot.id
	WHERE o.status_id <> 'закр'
		AND o.fin_id = @fin_id1
		AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR o.build_id = @build_id1)
		AND (@occ1 IS NULL OR o.Occ = @occ1)
		AND (
		(o.Whole_payment <> i.SumPaym OR i.Penalty_value <> (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) OR i.Occ IS NULL) OR (
		(o.fin_id <> ot.fin_id) OR (o.fin_id = ot.fin_id AND o.Data_rascheta > i.DateCreate)
		)
		)
	)
go

