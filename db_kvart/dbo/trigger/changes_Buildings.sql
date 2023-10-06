CREATE   TRIGGER [dbo].[changes_Buildings]
ON [dbo].[Buildings]
FOR INSERT, UPDATE, DELETE NOT FOR REPLICATION
/*
select * from Building_debug where build_id=6812 order by createAt desc
*/
AS
	SET NOCOUNT ON;

	-- определеяем тип произошедших изменений INSERT,UPDATE, or DELETE
	DECLARE @change_type AS VARCHAR(10)  = 'inserted'
	DECLARE @count AS INT = 0
	
	SELECT
		@count = COUNT(*)
	FROM DELETED
	
	IF @count > 0
	BEGIN
		SET @change_type = 'deleted'
		SELECT
			@count = COUNT(*)
		FROM INSERTED
		IF @count > 0
			SET @change_type = 'updated'
	END

	-- обработка удаления
	IF @change_type = 'deleted'
	BEGIN
		INSERT INTO Building_debug
		(build_id
		,change_type
		,tip_id
		,sector_id
		,street_id
		,nom_dom
		,town_id)
			SELECT
				id
			   ,@change_type
			   ,tip_id
			   ,sector_id
			   ,street_id
			   ,nom_dom
			   ,town_id
			FROM DELETED
	END
	ELSE
	BEGIN
		-- триггер не различает вставку и удаление, так что добавим ручную обработку
		-- обработка вставки
		IF @change_type = 'inserted'
		BEGIN
			INSERT INTO Building_debug
			(build_id
			,change_type
			,tip_id
			,sector_id
			,street_id
			,nom_dom
			,town_id)
				SELECT
					id
				   ,@change_type
				   ,tip_id
				   ,sector_id
				   ,street_id
				   ,nom_dom
				   ,town_id
				FROM INSERTED
		END
		-- обработка обновления
		ELSE
		BEGIN
			INSERT INTO Building_debug
			(build_id
			,change_type
			,tip_id
			,sector_id
			,street_id
			,nom_dom
			,town_id)
				SELECT
					id
				   ,@change_type
				   ,tip_id
				   ,sector_id
				   ,street_id
				   ,nom_dom
				   ,town_id
				FROM INSERTED
		END
	END -- завершение if
go

