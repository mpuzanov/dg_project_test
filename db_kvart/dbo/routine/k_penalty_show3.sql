CREATE   PROCEDURE [dbo].[k_penalty_show3]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL
)
AS
	/*
	
	Показывает детально суммы по задолженности
	
	k_penalty_show3 @occ1=31059, @fin_id1=236
	
	*/

	SET NOCOUNT ON
	SET LANGUAGE Russian


	IF (@fin_id1 IS NULL)
		OR (@fin_id1 = 0)
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT CONVERT(VARCHAR(12), dat1, 106) AS 'Дата1'
		 , CONVERT(VARCHAR(12), data1, 106) AS 'Дата2'
		 , kol_day AS 'Дней'
		 , kol_day_dolg AS 'Дней долга'
		 , dolg AS 'Долг'
		 , dolg_peny AS 'Долг пени'
		 , paid_pred AS 'Пред. начисл'
		 , paid_pred AS 'Начисление'
		 , Peny_old AS 'Пени стар'
		 , paymaccount_serv AS 'Оплачено'
		 , paymaccount_peny AS 'из них пени'
		 , Peny_old_new AS 'Пени стар изм.'
		 , Peny AS 'Пени'
		 , CASE
			   WHEN (p.proc_peny_day IS NOT NULL) THEN p.proc_peny_day
			   ELSE gv.PenyProc
		   END AS '% пени в день'
		 , gv2.StrMes AS 'Период долга'
		 , p.[description] AS 'Описание'
		 , p.occ
		 , p.fin_id
		 , P.StavkaCB AS 'Ставка ЦБ'
		 , p.peny_tmp
	FROM dbo.Peny_detail AS p
		JOIN dbo.Global_values gv ON p.fin_id = gv.fin_id
		LEFT JOIN dbo.Global_values gv2 ON p.fin_dolg = gv2.fin_id
	WHERE occ = @occ1
		AND p.fin_id = @fin_id1
	ORDER BY gv2.fin_id
		   , dat1
--ORDER BY dat1 DESC --data1
go

