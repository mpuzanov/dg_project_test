CREATE   PROCEDURE [dbo].[adm_info_show]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT = NULL
)
AS
/*
 Показываем значения по заданному фин. периоду

 exec adm_info_show 255, 1
*/
	SET NOCOUNT ON


	DECLARE @Fin_id SMALLINT
		  , @tip_name VARCHAR(20)
		  , @StrFinId VARCHAR(15)
		  , @KolLic INT
		  , @KolBuilds INT
		  , @KolFlats INT
		  , @KolPeople INT
		  , @SumOplata DECIMAL(15, 2)
		  , @SumOplataMes DECIMAL(15, 2)
		  , @SumValue DECIMAL(15, 2)
		  , @SumLgota DECIMAL(15, 2)
		  , @SumSubsidia DECIMAL(15, 2)
		  , @SumAdded DECIMAL(15, 2)
		  , @SumPaymAccount DECIMAL(15, 2)
		  , @SumPaymAccount_peny DECIMAL(15, 2)
		  , @SumPaymAccountCounter DECIMAL(15, 2) -- оплачено по счетчикам
		  , @SumPenalty DECIMAL(15, 2)
		  , @SumSaldo DECIMAL(15, 2)
		  , @SumTotal_SQ DECIMAL(15, 2) -- Общая площадь 
		  , @SumDolg DECIMAL(15, 2)  -- сумма долга
		  , @ProcentOplata DECIMAL(15, 2)  -- Процент оплаты 

	IF @tip_id1 IS NULL
		SELECT @tip_name = 'Весь доступный фонд'
	ELSE
		SELECT @tip_name = name
		FROM dbo.Occupation_Types
		WHERE id = @tip_id1;

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL);

	SELECT @Fin_id = ib.fin_id
		 , @StrFinId = StrFinId
		 , @KolLic = SUM(KolLic)
		 , @KolBuilds = SUM(KolBuilds)
		 , @KolFlats = SUM(KolFlats)
		 , @KolPeople = SUM(KolPeople)
		 , @SumOplata = SUM(SumOplata)
		 , @SumOplataMes = SUM(SumOplataMes)
		 , @SumValue = SUM(SumValue)
		 , @SumLgota = SUM(SumLgota)
		 , @SumSubsidia = SUM(SumSubsidia)
		 , @SumAdded = SUM(SumAdded)
		 , @SumPaymAccount = SUM(SumPaymAccount)
		 , @SumPaymAccount_peny = COALESCE(SUM(SumPaymAccount_peny), 0)
		 , @SumPaymAccountCounter = COALESCE(SUM(SumPaymAccountCounter), 0)
		 , @SumPenalty = SUM(SumPenalty)
		 , @SumSaldo = SUM(SumSaldo)
		 , @SumTotal_SQ = SUM(SumTotal_SQ)
		 , @SumDolg = SUM(SumDolg)
		 , @ProcentOplata = AVG(ProcentOplata)
	FROM dbo.Info_basa AS ib
		JOIN dbo.VOcc_types AS ot ON ib.tip_id = ot.id
	WHERE 
		ib.fin_id = @fin_id1
		AND (@tip_id1 is null OR @tip_id1 = tip_id)
	GROUP BY ib.fin_id
		   , StrFinId
	ORDER BY ib.fin_id DESC;


	SELECT *
	FROM (
	VALUES
		('Fin_id', STR(@Fin_id, 15), 'Код фин. периода'),
		('tip_name', @tip_name, 'Тип жилого фонда'),
		('StrFinId', @StrFinId, 'Фин. период'),
		('KolLic', STR(@KolLic, 15), 'Кол-во лицевых счетов'),
		('KolBuilds', STR(@KolBuilds, 15), 'Кол-во домов'),
		('KolFlats', STR(@KolFlats, 15), 'Кол-во квартир'),
		('KolPeople', STR(@KolPeople, 15), 'Кол-во людей'),
		('Saldo', STR(@SumSaldo, 15, 2), 'Сумма вх.сальдо'),
		('Value', STR(@SumValue, 15, 2), 'Сумма начислений'),
		('Lgota', STR(@SumLgota, 15, 2), 'Сумма льгот'),
		('Subsidia', STR(@SumSubsidia, 15, 2), 'Сумма субсидий'),
		('Added', STR(@SumAdded, 15, 2), 'Сумма разовых'),
		('OplataMes', STR(@SumOplataMes, 15, 2), 'Начисл. с учетом льгот,субс.,разовых'),
		('PaymAccount', STR(@SumPaymAccount, 15, 2), 'Сумма платежей'),
		('PaymAccountPeny', STR(@SumPaymAccount_peny, 15, 2), 'Оплачено пени'),
		('PaymAccountCounter', STR(@SumPaymAccountCounter, 15, 2), 'Оплачено по счетчикам'),
		('Penalty', STR(@SumPenalty, 15, 2), 'Сумма пени'),
		('Oplata', STR(@SumOplata, 15, 2), 'Сумма к оплате'),
		('Total_SQ', STR(@SumTotal_SQ, 15, 2), 'Общая площадь'),
		('Dolg', STR(@SumDolg, 15, 2), 'Сумма долга'),
		('ProcentOplata', STR(@ProcentOplata, 6, 2), 'Процент оплаты')
	) AS t(P1, P2, P3)
go

