-- dbo.view_month source

CREATE   VIEW [dbo].[view_month]  AS 
	-- (именительный) (родительный вопрос чего?) (предложный вопрос о чем?)
SELECT id, DateName(month,DateAdd(month,id,-1)) as name, name_rod, name_pred FROM 
	(VALUES
	(1, 'января','январе'),
	(2, 'февраля','феврале'),
	(3, 'марта','марте'),
	(4, 'апреля','апреле'),
	(5, 'мая','мае'),
	(6, 'июня','июне'),
	(7, 'июля','июле'),
	(8, 'августа','августе'),
	(9, 'сентября','сентябре'),
	(10, 'октября','октябре'),
	(11, 'ноября','ноябре'),
	(12, 'декабря','декабре')
	) X(id, name_rod, name_pred);
go

