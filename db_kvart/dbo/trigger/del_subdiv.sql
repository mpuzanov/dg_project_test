CREATE   TRIGGER [dbo].[del_subdiv]
ON [dbo].[Sector]
FOR DELETE
AS
	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM (SELECT
					t.fin_id
				   ,t.sector_id
				FROM dbo.Buildings_history AS t 
				UNION
				SELECT
					t.fin_current AS fin_id
				   ,t.sector_id
				FROM dbo.Buildings AS t) AS t1
			JOIN DELETED AS d
				ON t1.sector_id = d.id)
	BEGIN
		DECLARE @jeu	  SMALLINT
			   ,@jeu_name VARCHAR(50)
			   ,@msg	  VARCHAR(100)

		SELECT TOP (1)
			@jeu = d.id
		   ,@jeu_name = d.name
		FROM dbo.View_build_all_lite vba
		JOIN DELETED AS d
			ON vba.sector_id = d.id

		ROLLBACK TRAN
		SELECT
			@msg = CONCAT('Участок <', @jeu_name,' (', @jeu,')>  удалить нельзя! Т.к. с ним есть дома в истории')
		RAISERROR (@msg, 16, 10)
	END
go

