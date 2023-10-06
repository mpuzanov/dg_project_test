CREATE   PROCEDURE [dbo].[k_edit_occ_not_print]

(
	@typ	SMALLINT
	,@occ	INT	= NULL
	,@dom	INT	= NULL
)
AS
	/*
		Добавляем или удаляем строки в occ_not_print  
	*/
	SET NOCOUNT ON

	IF @typ = 1 --добавление лицевого
	BEGIN
		INSERT OCC_NOT_print
		(	Occ
			,address)
				SELECT
					o.Occ
					,o.address
				FROM dbo.OCCUPATIONS AS o
				WHERE o.Occ = @occ
				AND NOT EXISTS (SELECT
						*
					FROM dbo.OCC_NOT_print
					WHERE Occ = o.Occ)

	END

	IF @typ = 2  --удаление лицевого
	BEGIN
		DELETE dbo.OCC_NOT_print
		WHERE Occ = @occ

	END

	IF @typ = 3 --добавление лицевых для дома
	BEGIN
		INSERT OCC_NOT_print
		(	Occ
			,address)
				SELECT
					o.Occ
					,o.address
				FROM dbo.OCCUPATIONS AS o
				JOIN dbo.FLATS AS f
					ON f.id = o.flat_id
				JOIN dbo.BUILDINGS AS b
					ON b.id = f.bldn_id
				WHERE b.id = @dom
				AND NOT EXISTS (SELECT
						*
					FROM dbo.OCC_NOT_print
					WHERE Occ = o.Occ)

	END

	IF @typ = 4  --удаление лицевых для дома
	BEGIN
		DELETE onp
			FROM dbo.OCC_NOT_print AS onp
		WHERE EXISTS (SELECT
					*
				FROM dbo.OCCUPATIONS AS o
				JOIN dbo.FLATS AS f
					ON o.flat_id = f.id
				WHERE f.bldn_id = @dom
				AND o.Occ = onp.Occ)

	END
go

