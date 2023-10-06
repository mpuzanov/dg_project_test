CREATE   PROCEDURE [dbo].[adm_change_adres]
(
	@occ1		INT
   ,@street_id1 SMALLINT -- новый код улицы
   ,@nom_dom1   VARCHAR(12) -- новый дом
   ,@nom_kvr1   VARCHAR(20)  -- новая квартира
)
AS
/* 
Смена адреса у заданного лицевого счета
*/

	SET NOCOUNT ON

	DECLARE @flat_id1 INT

	SELECT
		@flat_id1 = f.id
	FROM dbo.Buildings AS b
	JOIN dbo.Flats AS f
		ON b.id = f.bldn_id
	WHERE b.street_id = @street_id1
	AND b.nom_dom = @nom_dom1
	AND f.nom_kvr = @nom_kvr1;

	IF @flat_id1 IS NOT NULL
	BEGIN  --меняем адрес у лицевого счета
		UPDATE dbo.Occupations
		SET flat_id = @flat_id1
		WHERE occ = @occ1;

		EXEC k_update_address @occ1;

	END
go

