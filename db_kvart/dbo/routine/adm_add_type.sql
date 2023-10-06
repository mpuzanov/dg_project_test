CREATE   PROCEDURE [dbo].[adm_add_type]
(
	  @name VARCHAR(50)
	, @fin_current SMALLINT = NULL
)
AS
	/*
		Добавление нового типа жил. фонда
	*/
	SET NOCOUNT ON

	IF @fin_current IS NULL
		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupation_Types
			WHERE name = @name
		)
	BEGIN
		DECLARE @id1 SMALLINT

		--найдем новый код
		SELECT TOP (1) @id1 = n
		FROM dbo.Fun_GetNums(1, 500) AS t
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.Occupation_Types AS ot
				WHERE t.n = ot.id
			)

		--SELECT @id1 = MAX(id)
		--FROM dbo.Occupation_Types
		--SELECT @id1 = COALESCE(@id1, 0) + 1

		INSERT INTO dbo.Occupation_Types (id
										, name
										, fin_id
										, id_accounts)
		VALUES(@id1
			 , @name
			 , @fin_current
			 , (SELECT TOP(1) ra.ID FROM Reports_account ra WHERE ra.visible = cast(1 as bit)))

		-- добавляем единицы измерения по этому типу жил. фонда
		IF NOT EXISTS (
				SELECT TOP (1) 1
				FROM dbo.Service_units 
				WHERE fin_id = @fin_current
					AND tip_id = @id1
			)
		BEGIN
			INSERT INTO dbo.Service_units (fin_id
										 , service_id
										 , roomtype_id
										 , tip_id
										 , unit_id)
			SELECT @fin_current
				 , service_id
				 , roomtype_id
				 , @id1
				 , unit_id
			FROM dbo.Service_units
			WHERE fin_id = @fin_current
				AND tip_id = (SELECT TOP(1) id FROM dbo.Occupation_Types ORDER BY id) -- берем из основного фонда

		END
	-- у него не должно быть ограничений  USERS_OCC_TYPES для него пустой
	END
	ELSE
		RAISERROR ('Такой тип жил.фонда уже есть!', 16, 10)
go

