CREATE   PROCEDURE [dbo].[k_showsuppliers2]
(
	@serv_str VARCHAR(1000) -- строка формата: код услуги;код услуги
)
AS
	/*
	Список поставщиков по услугам
	
	используется например в программе Перерасчёты получение Виновников
	
	exec k_showsuppliers2 'площ;хвод'
	*/
	SET NOCOUNT ON

	SELECT DISTINCT
		s1.name
		,s1.sup_id AS id
	FROM dbo.View_SUPPLIERS AS s1 
	JOIN (SELECT
			value AS id
		FROM STRING_SPLIT(@serv_str, ';') WHERE RTRIM(value) <> '') AS t
		ON s1.service_id = t.id
	ORDER BY s1.name
go

