-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_intPrint_basa_proverka]
(
	  @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @occ1 INT = NULL
)
AS
/*
exec k_intPrint_basa_proverka @tip_id1=4, @build_id1=null, @occ1=910003452
*/
BEGIN
	SET NOCOUNT ON;

	SELECT o.Occ
		 , o.Whole_payment
		 , i.SumPaym
		 , i.Penalty_value
		 , (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) AS Penalty_value_o
		 , i.DateCreate
		 , o.Data_rascheta
	FROM dbo.VOcc AS o 
		JOIN dbo.Flats f 
			ON o.flat_id = f.id
		JOIN dbo.VOcc_types AS t 
			ON o.tip_id = t.id
		LEFT JOIN dbo.Intprint AS i 
			ON o.Occ = i.Occ
			AND t.fin_id = i.fin_id
	WHERE o.status_id <> 'закр'
		AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR f.bldn_id = @build_id1)
		AND (@occ1 IS NULL OR o.Occ = @occ1)
		AND (
		o.Data_rascheta > i.DateCreate OR (o.Whole_payment <> i.SumPaym OR i.Penalty_value <> (o.Penalty_value + o.Penalty_added + o.Penalty_old_new) OR i.Occ IS NULL)
		)
END
go

