CREATE   PROCEDURE [dbo].[adm_add_fam]
(
	@id1	VARCHAR(10)
	,@name1	VARCHAR(30)
)
--
--  добавляем новый тип родственных отношений
--
AS
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM dbo.Fam_relations
			WHERE Id = @id1
			AND name = @name1)
	BEGIN
		INSERT dbo.Fam_relations
		(	Id
			,name)
		VALUES (@id1
				,@name1)
	END
	ELSE
		RAISERROR ('Такой тип  уже есть!', 16, 10)
go

