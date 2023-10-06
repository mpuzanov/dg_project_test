-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 8/5/2008
-- Description:	Добавление начислений от поставщика по узлу учета
-- =============================================
CREATE     PROCEDURE [dbo].[adm_add_build_value_source]
(
	@fin_id			SMALLINT
	,@service_id	VARCHAR(10)
	,@build_kod		INT
	,@value_source	DECIMAL(15, 2)
	,@res			BIT	= 0 OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- 1. Определяем код дома
	DECLARE @build_id INT = NULL
	
	SELECT
		@build_id = build_id
	FROM dbo.Build_source_id
	WHERE 
		service_id = @service_id
		AND kod = @build_kod

	IF @build_id IS NULL
	BEGIN
		--raiserror('Код узла учета %d по услуге %s не заведен!',16,1,@build_kod,@service_id)
		SET @res = 0
		RETURN 0
	END

	IF EXISTS (SELECT
				1
			FROM dbo.Build_source_value
			WHERE 
				fin_id = @fin_id
				AND service_id = @service_id
				AND build_id = @build_id)
	BEGIN
		UPDATE dbo.Build_source_value
		SET value_source = @value_source
		WHERE 
			fin_id = @fin_id
			AND service_id = @service_id
			AND build_id = @build_id
	END
	ELSE
	BEGIN
		INSERT
		INTO dbo.Build_source_value
		(	fin_id
			,service_id
			,build_id
			,value_source)
		VALUES (@fin_id
				,@service_id
				,@build_id
				,@value_source)
	END

	SET @res = 1

END
go

