CREATE   PROCEDURE [dbo].[k_send_email]
(
      @recipients VARCHAR(MAX),
      @subject VARCHAR(MAX),
      @body VARCHAR(MAX)
)
WITH EXECUTE AS 'dbo'
AS 
BEGIN
	IF (@body IS NOT NULL AND @subject IS NOT NULL AND @recipients IS NOT NULL)
	begin
		EXEC msdb.[dbo].[sp_send_dbmail] 
            --@profile_name = 'TEST_PROFILE', 
            @recipients = @recipients, 
            @subject = @subject, 
            @body = @body, 
            @body_format = 'TEXT';
	end
END
go

