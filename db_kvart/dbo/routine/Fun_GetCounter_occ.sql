CREATE   FUNCTION [dbo].[Fun_GetCounter_occ]
(
	  @counter_id1 INT
	, @fin_id1 SMALLINT = NULL
)
RETURNS INT
AS
BEGIN
	/*
	Функция возвращает количество лицевых счетов на счетчике
	
	Дата :  12/04/2005
	Автор : Пузанов М.А.
	select dbo.Fun_GetCounter_occ(74489, 239)
	
	*/

	IF @fin_id1 IS NULL
	BEGIN
		SELECT @fin_id1 = b.fin_current
		FROM dbo.Counters c
			JOIN dbo.Buildings b ON c.build_id = b.id
		WHERE c.id = @counter_id1
	END

	RETURN COALESCE((
		SELECT COUNT(cl.Occ)
		FROM dbo.Counter_list_all cl
			JOIN Occupations o ON cl.Occ = o.Occ
		WHERE cl.counter_id = @counter_id1
			AND cl.fin_id = @fin_id1
			AND o.total_sq > 0
			AND o.status_id <> 'закр'
	), 0)

END
go

