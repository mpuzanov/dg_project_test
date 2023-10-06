CREATE   PROCEDURE [dbo].[k_counter_paym_id]
(
	  @counter_id1 INT
	, @kod_insp1 INT = NULL
)
AS
	/*
	
	Показываем начисления по  заданному счетчику
	
	Используется в Картотеке
	
	EXEC dbo.[k_counter_paym_id] @counter_id1=97914
	
	EXEC dbo.[k_counter_paym_id] @counter_id1=97914,@kod_insp1=2524354
	
	*/
	SET NOCOUNT ON


	SELECT cp2.StrFinPeriod AS 'Фин.период'
				  , cp.kol_day AS 'Кол.дней'
				  , cp.value_vday AS 'Кол. в день'
				  , CAST((cp.kol_day * cp.value_vday) AS DECIMAL(18, 8)) AS 'Кол. в месяц'
				  , cp.tarif AS 'Тариф'
				  , cp.value AS 'Начисл.'
				  , cp.counter_id
				  , cp.kod_insp
				  , cp.fin_id
				  , cp.tip_value
	FROM dbo.Counter_paym AS cp 
		INNER JOIN dbo.Calendar_period cp2 ON cp2.fin_id = cp.fin_id
	WHERE cp.counter_id = @counter_id1
		AND (@kod_insp1 is null OR cp.kod_insp = @kod_insp1)
	ORDER BY cp.fin_id DESC
go

