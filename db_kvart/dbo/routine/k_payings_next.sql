CREATE   PROCEDURE [dbo].[k_payings_next]
AS
/*
	--  Процедура возвращает максимальное значение ключа в таблице PAYINGS
*/

	DECLARE	@occ_next	INT
			,@kod		INT	= 6

	UPDATE KEY_ID 
	SET @occ_next = key_max = key_max + 1
	WHERE id = @kod

	RETURN @occ_next
go

