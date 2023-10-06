-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Расчёт коэффициентов по домам за найм
-- =============================================
CREATE         PROCEDURE [dbo].[adm_koef_build]
(
	@build_id INT = NULL
   ,@debug	  BIT = 0
)
AS
BEGIN
	/*
	adm_koef_build null, 1
	*/
	SET NOCOUNT ON;

	DECLARE @build_id1		 INT
		   ,@msg_debug		 VARCHAR(100)
		   ,@div_name		 VARCHAR(50)
		   ,@material		 VARCHAR(50)
		   ,@garbage		 VARCHAR(20)
		   ,@lift			 VARCHAR(20)
		   ,@central_heating VARCHAR(50)
		   ,@koef_value		 DECIMAL(6, 4)


	DECLARE @K1 DECIMAL(6, 4)  -- строительный материал
		   ,@K2 DECIMAL(6, 4) -- благоустройство 
		   ,@K3 DECIMAL(6, 4) -- районы

		   ,@KM DECIMAL(6, 4) -- Мусоропровод
		   ,@KL DECIMAL(6, 4) -- Лифт
		   ,@KO DECIMAL(6, 4) -- центральное Отопление ГВС

	DECLARE cur CURSOR LOCAL FOR
		SELECT
			kb.build_id
		   ,kb.div_name
		   ,kb.material
		   ,kb.garbage
		   ,kb.lift
		   ,kb.central_heating
		FROM dbo.KOEF_BUILD kb
		WHERE (kb.build_id = @build_id
		OR @build_id IS NULL)

	OPEN cur

	FETCH NEXT FROM cur INTO @build_id1, @div_name, @material, @garbage, @lift, @central_heating

	WHILE @@fetch_status = 0
	BEGIN

		SELECT
			@K1 = value
		FROM dbo.KOEF
		WHERE is_build = 1
		AND level1 = 10
		AND name = @material
		SELECT
			@K3 = value
		FROM dbo.KOEF
		WHERE is_build = 1
		AND level1 = 9
		AND name = @div_name
		SELECT
			@KM = value
		FROM dbo.KOEF
		WHERE is_build = 1
		AND level1 = 12
		AND name = @garbage
		SELECT
			@KL = value
		FROM dbo.KOEF
		WHERE is_build = 1
		AND level1 = 11
		AND name = @lift
		SELECT
			@KO = value
		FROM dbo.KOEF
		WHERE is_build = 1
		AND level1 = 13
		AND name = @central_heating

		SET @msg_debug = CONCAT('@build_id1: ',@build_id1,
			',@K1: ',STR(@K1, 6, 4),', @K3: ',STR(@K3, 6, 4),', @KM: ', STR(@KM, 6, 4), ', @KL: ',STR(@KL, 6, 4),', @KO: ',STR(@KO, 6, 4))

		IF @debug = 1
			RAISERROR (@msg_debug, 10, 1) WITH NOWAIT;

		SELECT
			@K2 = (COALESCE(@KM, 1) + COALESCE(@KL, 1) + COALESCE(@KO, 1)) / 3
		SELECT
			@koef_value = (COALESCE(@K1, 1) + COALESCE(@K2, 1) + COALESCE(@K3, 1)) / 3

		UPDATE dbo.KOEF_BUILD
		SET value = @koef_value
		WHERE build_id = @build_id1;

		FETCH NEXT FROM cur INTO @build_id1, @div_name, @material, @garbage, @lift, @central_heating

	END

	CLOSE cur
	DEALLOCATE cur
END
go

