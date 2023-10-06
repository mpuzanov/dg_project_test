CREATE PROCEDURE [dbo].[k_occ_next]
AS
	/*
	--  Сейчас используется k_occ_new
	--
	--  Процедура возвращает максимальное значение ключа в таблице OCCUPATIONS
	*/
	DECLARE @occ_next INT

	UPDATE KEY_ID WITH (ROWLOCK)
	SET @occ_next = key_max = key_max + 1
	WHERE id = 1

	RETURN @occ_next
go

