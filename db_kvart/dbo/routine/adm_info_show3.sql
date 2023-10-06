CREATE   PROCEDURE [dbo].[adm_info_show3]
(
	@tip_id	 SMALLINT = NULL
   ,@fin_id1 SMALLINT = NULL
   ,@fin_id2 SMALLINT = NULL
)
AS
	/*
	  Показываем общие данные по базе данных
	   
	  exec adm_info_show3 1
	  exec adm_info_show3 null,190,195
	*/
	SET NOCOUNT ON

	-- по умолчанию показываем за последний год
	IF @fin_id1 IS NULL
		AND @fin_id2 IS NULL
	BEGIN
		-- Определяем текущий период
		DECLARE @fin_current SMALLINT

		SELECT
			@fin_current = fin_id
		FROM Global_values gv
		WHERE 
			current_timestamp BETWEEN gv.start_date AND gv.end_date;

		IF @fin_current IS NULL
			SELECT TOP 1
				@fin_current = fin_id
			FROM Global_values gv
			ORDER BY gv.fin_id DESC;

		SELECT
			@fin_id2 = @fin_current
		   ,@fin_id1 = @fin_current - 12;
	END

	--PRINT @fin_id1
	--PRINT @fin_id2

	SELECT
		ot.Name AS tip_name
	   ,ib.sup_name
	   ,ot.payms_value
	   ,ot.start_date
	   ,ib.fin_id
	   ,ib.tip_id
	   ,ib.StrFinId
	   ,ib.KolLic
	   ,ib.KolBuilds
	   ,ib.KolFlats
	   ,ib.KolPeople
	   ,ib.SumOplata
	   ,ib.SumOplataMes
	   ,ib.SumValue
	   ,ib.SumLgota
	   ,ib.SumSubsidia
	   ,ib.SumAdded
	   ,ib.SumPaymAccount
	   ,ib.SumPaymAccount_peny
	   ,ib.SumPaymAccountCounter
	   ,ib.SumPenalty
	   ,ib.SumSaldo
	   ,ib.SumTotal_SQ
	   ,ib.SumDolg
	   ,ib.ProcentOplata
	   ,ib.SumDebt
	FROM dbo.Info_basa AS ib 
	JOIN dbo.VOcc_types_all AS ot 
		ON ib.tip_id = ot.id
		AND ib.fin_id = ot.fin_id
	WHERE 
		(@tip_id IS NULL OR ib.tip_id = @tip_id)
		AND ib.fin_id BETWEEN @fin_id1 AND @fin_id2
	ORDER BY ib.fin_id DESC, tip_id;
go

