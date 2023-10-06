CREATE   TRIGGER [dbo].[update_consmodes_list]
ON [dbo].[Consmodes_list]
AFTER UPDATE
AS
	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM INSERTED
			WHERE fin_id IS NULL)
	BEGIN
		UPDATE cl
		SET fin_id = b.fin_current
		FROM dbo.Consmodes_list AS cl
		JOIN INSERTED AS i	ON 
			cl.occ = i.occ
			AND cl.service_id = i.service_id
		JOIN dbo.OCCUPATIONS AS o ON 
			i.occ = o.occ
		JOIN dbo.Flats AS f ON 
			o.flat_id=f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id=b.id
		WHERE cl.fin_id IS NULL
	END

	-- если есть изменения в этих полях то ведём лог
	IF EXISTS (
			SELECT
				i.occ
			   ,i.service_id
			   ,i.sup_id
			   ,i.mode_id
			   ,i.source_id
			FROM INSERTED i
			EXCEPT
			SELECT
				d.occ
			   ,d.service_id
			   ,d.sup_id
			   ,d.mode_id
			   ,d.source_id
			FROM DELETED d
			)
	BEGIN

		DECLARE 
			@user_id1 SMALLINT = dbo.Fun_GetCurrentUserId()
			,@comments VARCHAR(100)='изменние режимов или поставщиков'
			,@op_id VARCHAR(10) = 'рдлс'
			,@date_edit SMALLDATETIME = CAST(current_timestamp AS DATE)

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
				,@comments
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
				AND op.comments = @comments
			)

	END
go

