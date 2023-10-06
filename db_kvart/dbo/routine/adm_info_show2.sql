CREATE   PROCEDURE [dbo].[adm_info_show2]
(
	@fin_id1 SMALLINT
   ,@tip_id1 SMALLINT
)
AS
/*
Показываем значения по заданному фин. периоду

exec adm_info_show2 255, 1
*/
	SET NOCOUNT ON

	SELECT
		*
	FROM (SELECT TOP 15
			ib.Fin_id as Fin_id
		   ,StrFinId as StrFinId
		   ,SUM(KolLic) as KolLic
		   ,SUM(KolBuilds) as KolBuilds
		   ,SUM(KolFlats) as KolFlats
		   ,SUM(KolPeople) as KolPeople
		   ,SUM(SumOplata) as Oplata
		   ,SUM(SumOplataMes) as OplataMes
		   ,SUM(SumValue) as [Value]
		   ,SUM(SumLgota) as Lgota
		   ,SUM(SumSubsidia) as Subsidia
		   ,SUM(SumAdded) as Added
		   ,SUM(SumPaymAccount) as PaymAccount
		   ,SUM(SumPaymAccount_peny) as PaymAccountPeny
		   ,SUM(SumPaymAccountCounter) as PaymAccountCounter
		   ,SUM(SumPenalty) as Penalty
		   ,SUM(SumSaldo) as Saldo
		   ,SUM(SumTotal_SQ) as Total_SQ
		   ,SUM(SumDolg) as Dolg
		   ,SUM(ProcentOplata) as ProcentOplata
		FROM dbo.Info_basa AS ib
		JOIN dbo.VOcc_types AS ot
			ON ib.tip_id = ot.id
		WHERE ib.Fin_id = @fin_id1
		AND tip_id = @tip_id1
		GROUP BY ib.Fin_id
				,StrFinId) AS f
	ORDER BY fin_id;
go

