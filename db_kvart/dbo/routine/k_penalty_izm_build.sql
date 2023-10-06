-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Обнуление пени из АРМ "Администратор
-- =============================================
CREATE     PROCEDURE [dbo].[k_penalty_izm_build]
(
	@tip_id		SMALLINT	= NULL
	,@build_id	INT			= NULL
	,@sup_id	INT			= NULL
	,@comment	VARCHAR(50)	= NULL
)
AS
/*
k_penalty_izm_build 28,1058,323
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @tip_id IS NULL AND @build_id IS NULL
		RETURN

	DECLARE	@occ1 INT	

	IF COALESCE(@comment, '') = ''
		SET @comment = 'Обнуление пени из АРМ "Администратор"'

	DECLARE cursor_name CURSOR LOCAL FOR
		SELECT
			o.occ
		FROM [dbo].[OCCUPATIONS] AS o 
		JOIN dbo.FLATS F 
			ON F.id = o.flat_id
		WHERE 
			(F.bldn_id = @build_id OR @build_id IS NULL)
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)
			AND (o.status_id <> 'закр')

	OPEN cursor_name;

	FETCH NEXT FROM cursor_name INTO @occ1;

	WHILE @@fetch_status = 0
	BEGIN

		EXEC dbo.k_vvod_penalty	@occ1 = @occ1
								,@Peny_old1 = 0
								,@comments1 = @comment
								,@sup_id1 = @sup_id

		FETCH NEXT FROM cursor_name INTO @occ1;

	END

	CLOSE cursor_name;
	DEALLOCATE cursor_name;
END
go

