CREATE   PROCEDURE [dbo].[k_update_address]
(
	@occ1 INT
)
AS
	/*
		--  обновляем адрес  лицевого счета
	*/
	SET NOCOUNT ON

	UPDATE o 
	SET address = [dbo].[Fun_GetAdres](f.bldn_id, f.id, o.occ)
	FROM dbo.OCCUPATIONS AS o
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	WHERE occ = @occ1
go

