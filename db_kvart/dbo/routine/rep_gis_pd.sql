-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[rep_gis_pd]
(
	@fin_id	  SMALLINT
   ,@tip_id	  SMALLINT
   ,@build_id INT = NULL
   ,@sup_id	  INT = NULL
   ,@town_id  INT = NULL
)
AS
/*
rep_gis_pd @fin_id=255, @tip_id=1, @build_id=1031, @sup_id=null
rep_gis_pd @fin_id=255, @tip_id=4, @build_id=null, @sup_id=323
EXEC rep_gis_pd @fin_id=256, @tip_id=1, @build_id=6785, @town_id=1
*/
BEGIN
	SET NOCOUNT ON;

	--IF DB_NAME() IN ('komp', 'naim')
	--	AND system_user <> 'sa'
	--	SET @tip_id = -1

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @town_id IS NULL
		SELECT
			@build_id = 0
		   ,@sup_id = 0
		   ,@fin_id = 0
		   ,@tip_id = 0

	--IF @build_id IS NULL
	--BEGIN
	--	RAISERROR ('Данные формируются только по дому!', 16, 1);
	--   	RETURN
	--   END

	IF COALESCE(@sup_id, 0) = 0
	BEGIN
		-- Блокируем кого в ГИС не выгружаем
		IF EXISTS (SELECT
					1
				FROM dbo.Occupation_types AS ot
				WHERE ot.id = @tip_id
				AND ot.export_gis = 0)
			SELECT
				@tip_id = 0
			   ,@fin_id = 999
			   ,@build_id = 0

		EXEC k_intPrint_occ @fin_id1 = @fin_id
						   ,@tip_id = @tip_id
						   ,@build = @build_id
						   ,@town_id = @town_id
							--,@debug=1
						   ,@is_out_gis = 1

	END
	ELSE
	BEGIN
		-- Выгружаем кому разрешено
		IF NOT EXISTS (SELECT
					1
				FROM dbo.Suppliers_types st
				WHERE st.tip_id = @tip_id
				AND st.sup_id = @sup_id
				AND st.export_gis = 0)

			EXEC k_intPrint_occ_sup @fin_id1 = @fin_id
								   ,@tip_id = @tip_id
								   ,@build = @build_id
								   ,@sup_id = @sup_id
								   ,@town_id = @town_id
									--,@debug=1
								   ,@is_out_gis = 1
	END


END
go

