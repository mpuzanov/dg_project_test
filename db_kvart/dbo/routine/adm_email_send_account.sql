-- =============================================
-- Author:		Пузанов
-- Create date: 24.04.2014
-- Description:	Отправка квитанций по почте с FTP - сервера
-- =============================================
CREATE     PROCEDURE [dbo].[adm_email_send_account]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@occ1			INT
			,@email			VARCHAR(50)
			,@fileName		VARCHAR(50)
			,@mailitem_id	INT
			,@fin_id		SMALLINT

	DECLARE cur CURSOR LOCAL FOR
		--SELECT
		--	[occ] = 680003554		
		--	,[email] = 'mpuzanov@mail.ru'
		--	,[fileName] = '20140301_680003554_Acc.PDF'

		SELECT
			ae.Occ
			,ae.email
			,ae.[fileName]
			,ae.fin_id
		FROM [dbo].[ACCOUNT_EMAIL] AS ae
		JOIN dbo.OCCUPATIONS AS o
			ON ae.Occ = o.Occ 
			AND ae.fin_id = o.fin_id		
		WHERE email_out = 0

	OPEN cur

	FETCH NEXT FROM cur INTO @occ1, @email, @fileName, @fin_id

	WHILE @@fetch_status = 0
	BEGIN

		SELECT
			@mailitem_id = 0
			,@fileName = 'r:\fz_files\account\' + @fileName

		EXEC msdb.dbo.sp_send_dbmail	@recipients = @email
										,@file_attachments = @fileName
										,@body = 'На письмо отвечать не надо'
										,@subject = 'Квитанция из МФЦ'
										,@mailitem_id = @mailitem_id OUT
		--PRINT @mailitem_id
		--PRINT @email
		--PRINT @fileName
		
		IF @mailitem_id > 0
			UPDATE [ACCOUNT_EMAIL]
			SET	dateOut		= current_timestamp
				,email_out	= 1
			WHERE fin_id = @fin_id
			AND Occ = @occ1

		FETCH NEXT FROM cur INTO @occ1, @email, @fileName, @fin_id

	END

	CLOSE cur
	DEALLOCATE cur

END
go

