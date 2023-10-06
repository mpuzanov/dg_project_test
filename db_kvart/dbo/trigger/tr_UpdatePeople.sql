-- =============================================
-- Author:		Пузанов
-- Create date: 21.12.2011
-- Description:	Сохраняем историю изменения Ф.И.О.
-- =============================================
CREATE                         TRIGGER [dbo].[tr_UpdatePeople]
ON [dbo].[People]
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @date_change SMALLDATETIME = CAST(current_timestamp as DATE)

	IF EXISTS (
			SELECT
				i.id
				,i.last_name
				,i.first_name
				,i.second_name
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id
				,d.last_name
				,d.first_name
				,d.second_name
			FROM DELETED d
			)
	BEGIN

		IF NOT EXISTS (SELECT
					1
				FROM dbo.Fio_history as fh
				JOIN DELETED as d ON 
					d.id = fh.owner_id
				WHERE fh.date_change = @date_change)

			INSERT INTO dbo.Fio_history
			(owner_id
			,date_change
			,last_name
			,first_name
			,second_name
			,sysuser)
				SELECT
					id
					,@date_change
					,Last_name
					,First_name
					,Second_name
					,system_user
				FROM DELETED
	END

	UPDATE p
	SET DateEdit = @date_change
		,user_edit = dbo.Fun_GetCurrentUserId()
		,is_owner_flat = CASE
			WHEN i.Dola_priv1>0 OR i.Dola_priv2>0 THEN 1
			WHEN i.Status2_id in ('влпр','1019') THEN 1  -- Владелец кв.(не прописан) или Собственник без регистрации 
			ELSE i.is_owner_flat
		END
	FROM dbo.PEOPLE AS p
	JOIN INSERTED AS i ON 
		p.id=i.id
	

END
go

