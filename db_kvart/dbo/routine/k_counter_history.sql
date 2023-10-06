CREATE   PROCEDURE [dbo].[k_counter_history]
(
	@counter_id1 INT
)
AS
	/*
		Список изменений по заданному счетчику
		
		k_counter_history 859
	*/

	SET NOCOUNT ON

	SELECT
		c.id
	   ,u.Initials AS 'Имя пользователя'
	   ,o.name AS 'Виды работ'
	   ,CONVERT(VARCHAR(12), c.date_edit, 106) AS 'Дата'
	   ,c.comments AS 'Комментарий'
	   ,c.comments
	FROM dbo.Counter_log AS c 
	LEFT OUTER JOIN dbo.Operations AS o 
		ON c.op_id = o.op_id
	LEFT JOIN dbo.Users AS u
		ON c.user_id = u.id
	WHERE c.counter_id = @counter_id1
	ORDER BY c.date_edit DESC, c.id DESC
go

