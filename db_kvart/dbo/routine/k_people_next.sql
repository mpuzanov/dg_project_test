CREATE PROCEDURE [dbo].[k_people_next]
AS
/*
	Процедура возвращает максимальное значение ключа в таблице PEOPLE

!!!	Сейчас использую последовательности
SET @id1 = NEXT VALUE FOR dbo.GeneratePeolpleSequence;

*/
	DECLARE @id_next INT = NEXT VALUE FOR dbo.GeneratePeolpleSequence

	--UPDATE dbo.KEY_ID WITH (ROWLOCK)
	--SET @id_next = key_max = key_max + 1
	--WHERE id = 2

	RETURN @id_next
go

