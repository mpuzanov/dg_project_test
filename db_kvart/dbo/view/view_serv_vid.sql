-- dbo.view_serv_vid source

CREATE   VIEW [dbo].[view_serv_vid]
AS

	SELECT *
	FROM (
	  VALUES ('хвод','ХВС')
	  , ('гвод','ГВС')
	  , ('элек','Элек')
	  , ('отоп','Отоп')
	  , ('пгаз','Газ')
	) AS t(id, name);
go

