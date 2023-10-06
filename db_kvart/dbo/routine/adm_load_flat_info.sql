-- =============================================
-- Author:		Пузанов
-- Create date: 23.06.2020
-- Description:	Обновляем информацию по квартирам
-- =============================================
CREATE       PROCEDURE [dbo].[adm_load_flat_info]
(
	@flat_id1  INT
   ,@approach1 SMALLINT = NULL
   ,@floor1	   SMALLINT = NULL
   ,@rooms1	   SMALLINT = NULL
   ,@ResultAdd BIT		= 0
)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE dbo.FLATS
	SET approach = CASE
                       WHEN @approach1 > 0 THEN @approach1
                       ELSE approach
        END
	   ,floor	 = CASE
                        WHEN @floor1 > 0 THEN @floor1
                        ELSE floor
        END
	   ,ROOMS	 = CASE
                        WHEN @rooms1 > 0 THEN @rooms1
                        ELSE ROOMS
        END
	WHERE id = @flat_id1
	SET @ResultAdd = @@rowcount


	IF @rooms1 IS NOT NULL
	BEGIN
		UPDATE dbo.Occupations 
		SET ROOMS = CASE
                        WHEN @rooms1 > 0 THEN @rooms1
                        ELSE ROOMS
            END
		WHERE flat_id = @flat_id1
		SET @ResultAdd = @@rowcount
	END

	-- создаём записи в таблице ROOMS
	IF @rooms1 IS NOT NULL
	BEGIN
		-- получаем текущее кол-во комнат в таблице
		DECLARE @kolrooms SMALLINT = 0
		SELECT
			@kolrooms = COUNT(id)
		FROM dbo.ROOMS 
		WHERE flat_id = @flat_id1

		IF @kolrooms <> @rooms1
		BEGIN

			MERGE dbo.ROOMS AS T USING (SELECT
					CAST(n AS VARCHAR(12))
				FROM dbo.Fun_GetNums(1, @rooms1)) AS S (num_room)
			ON (T.flat_id = @flat_id1
				AND T.name = S.num_room)
			WHEN MATCHED
				THEN UPDATE
					SET [name] = S.num_room
			WHEN NOT MATCHED BY TARGET
				THEN INSERT
					(flat_id
					,[name])
					VALUES (@flat_id1
						   ,S.num_room)
			WHEN NOT MATCHED BY SOURCE AND T.flat_id = @flat_id1
				THEN DELETE
			;

		END

		
	END
	
END
go

