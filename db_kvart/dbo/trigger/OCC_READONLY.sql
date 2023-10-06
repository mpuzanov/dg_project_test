CREATE   TRIGGER [dbo].[OCC_READONLY]
ON [dbo].[Occupations]
FOR INSERT, UPDATE, DELETE
AS
	SET NOCOUNT ON

	IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted) 
		-- тригер insert
		UPDATE t
		SET date_create = current_timestamp
		FROM INSERTED AS i
		JOIN Occupations as t ON 
			t.occ = i.occ

	IF (system_user IN ('sa'))
		RETURN -- sa не логировать

	-- если есть изменения в этих полях то ведём лог
	IF EXISTS (
			SELECT
				i.occ
			   ,i.roomtype_id
			   ,i.proptype_id
			   ,i.status_id
			   ,i.living_sq
			   ,i.total_sq
			   ,i.teplo_sq
			   ,i.flat_id
			   ,i.comments
			   ,i.comments2
			   ,i.Penalty_calc
			FROM INSERTED i
			EXCEPT
			SELECT
				d.occ
			   ,d.roomtype_id
			   ,d.proptype_id
			   ,d.status_id
			   ,d.living_sq
			   ,d.total_sq
			   ,d.teplo_sq
			   ,d.flat_id
			   ,d.comments
			   ,d.comments2
			   ,d.Penalty_calc
			FROM DELETED d
			)
	BEGIN

		DECLARE @user_id1 SMALLINT
			   ,@state_id VARCHAR(10)
			   ,@op_id VARCHAR(10) = 'рдлс'
			   ,@date_edit SMALLDATETIME = CAST(current_timestamp AS DATE)

		SELECT TOP (1)
		   @state_id = dbo.Fun_GetRejimOcc(occ)
		   ,@user_id1 = dbo.Fun_GetCurrentUserId()
		FROM DELETED AS t1

		IF EXISTS (SELECT
					1
				FROM dbo.Group_membership
				WHERE 
					group_id = 'оптч'
					AND user_id = @user_id1)
			OR (@state_id <> 'норм')
		BEGIN
			-- если есть доступ к платежам - разрешить
			IF NOT EXISTS (SELECT
						dbo.Fun_AccessPayLic())
			BEGIN
				--RAISERROR ('У Вас доступ только для чтения', 16, 1);
				ROLLBACK TRAN
				RETURN
			END
		END

		-- залогируем изменения
		INSERT INTO dbo.Op_Log
		(	user_id
			,op_id
			,occ
			,done
			,comments
			,comp)
		SELECT @user_id1
				,@op_id
				,i.Occ
				,@date_edit
				,NULL
				,HOST_NAME()
		FROM INSERTED i
		WHERE NOT EXISTS (SELECT
				1
			FROM dbo.Op_Log op				
			WHERE 
				op.[user_id] = @user_id1
				AND op.occ = i.Occ
				AND op.op_id = @op_id			
				AND op.done = @date_edit
				AND op.comments IS NULL
			)

	END
go

