CREATE   PROCEDURE [dbo].[k_bankcount_show]
(
	@owner_id1 INT
)
AS
	/*
	Список банковских счетов человека
	
	Пузанов
	25.08.2005
	*/
	SET NOCOUNT ON

	SELECT
		CASE
			WHEN active = 1 THEN 'Да'
			ELSE 'Нет'
		END AS ActiveStr
	   ,t1.id
	   ,t1.owner_id
	   ,t1.active
	   ,t1.name
	   ,t1.number
	   ,t1.number2
	   ,t1.data_open
	   ,t1.data_close
	   ,t1.bank_id
	   ,t2.short_name AS bank_name
	   ,t1.date_edit
	   ,dbo.Fun_GetFIOUser(t1.user_edit) AS user_name
	   ,dbo.Fun_InitialsPeople(t1.owner_id) AS Initials
	   ,t1.otd
	   ,t1.fil
	   ,t1.KODI
	   ,t1.tnomer
	FROM dbo.BANK_COUNTS AS t1
	JOIN dbo.View_BANK AS t2 
		ON t1.bank_id = t2.id
	WHERE t1.owner_id = @owner_id1
	ORDER BY t1.active DESC
go

