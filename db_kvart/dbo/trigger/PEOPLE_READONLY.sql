CREATE   TRIGGER [dbo].[PEOPLE_READONLY]
ON [dbo].[People]
FOR INSERT, UPDATE, DELETE
AS
	SET NOCOUNT ON

	DECLARE @status_id VARCHAR(10)
		   ,@occ1	   INT
		   ,@state_id  VARCHAR(10)
		   ,@user_id1  SMALLINT

	SELECT
		@status_id = o.status_id
	   ,@occ1 = o.occ
	   ,@state_id = dbo.Fun_GetRejimOcc(o.occ)
	   ,@user_id1 = dbo.Fun_GetCurrentUserId()
	FROM INSERTED AS i
	JOIN dbo.OCCUPATIONS AS o ON 
		i.occ = o.occ

	IF EXISTS (SELECT
				1
			FROM dbo.GROUP_MEMBERSHIP 
			WHERE group_id = 'оптч'
			AND [user_id] = @user_id1)
		OR (@state_id <> 'норм')
	BEGIN
		--RAISERROR ('Режим чтение', 16, 1) WITH NOWAIT;
		ROLLBACK TRAN
		RETURN
	END

	IF (@status_id = 'закр')
	BEGIN
		ROLLBACK TRAN
		RAISERROR ('Лицевой %d закрыт! Изменения по нему проводить нельзя', 16, 10, @occ1)
		RETURN
	END

	IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted) 
		-- тригер insert
		UPDATE t
		SET date_create = current_timestamp
		FROM INSERTED AS i
		JOIN People as t ON 
			t.id = i.id

	-- проверяем нет ли 2-х ответственных на лицевом
	IF NOT EXISTS (SELECT
				d.Fam_id
			FROM DELETED d
			INTERSECT  -- выводит одинаковые записи
			SELECT
				i.Fam_id
			FROM INSERTED i)
	BEGIN
		IF EXISTS (SELECT
					occ
				   ,Fam_id
				   ,COUNT(*)
				FROM INSERTED
				WHERE Del = CAST(0 AS BIT)
				AND Fam_id = 'отвл'
				GROUP BY occ
						,Fam_id
				HAVING COUNT(*) > 1)
		BEGIN
			ROLLBACK TRAN
			RAISERROR ('На лицевом %d не может быть больше 2-х "Ответственных лиц"!', 16, 10, @occ1)
			RETURN
		END

	END
go

