-- =============================================
-- Author:		Пузанов
-- Create date: 26.05.2010
-- Description:	Проверка сообщения для пользователя
-- =============================================
CREATE     PROCEDURE [dbo].[k_msg_read]
(
	@ip VARCHAR(15) = NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	IF @ip = ''
		SET @ip = NULL

	-- 5 сек ждем блокировку  в этой сесии пользователя
	SET LOCK_TIMEOUT 5000

	DECLARE @user_login VARCHAR(30)	  = system_user -- логин текущего пользователя
		   ,@CurrenDate SMALLDATETIME = current_timestamp

	--print @user_login

	DECLARE @t TABLE
		(
			id			 INT		 PRIMARY KEY
		   ,date_msg	 SMALLDATETIME
		   ,from_user	 VARCHAR(50)
		   ,from_login	 VARCHAR(30)
		   ,msg_text	 VARCHAR(500)
		   ,to_ip		 VARCHAR(15)
		   ,from_ip		 VARCHAR(15)
		   ,FileName_msg VARCHAR(50) DEFAULT NULL
		)

	INSERT INTO @t
	(id
	,date_msg
	,from_user
	,from_login
	,msg_text
	,to_ip
	,from_ip
	,FileName_msg)
		SELECT
			M.id
		   ,M.date_msg
		   ,u.Initials
		   ,M.from_login
		   ,M.msg_text
		   ,M.to_ip
		   ,M.from_ip
		   ,CASE
				WHEN M.file_msg IS NULL THEN NULL
				WHEN COALESCE(M.FileName_msg, '') = '' THEN NULL
				ELSE M.FileName_msg
			END AS FileName_msg
		FROM dbo.MESSAGES_USERS AS M 
		JOIN dbo.USERS AS u
			ON M.from_login = u.login
		WHERE to_login = @user_login
		AND receive IS NULL
		AND (date_timeout IS NULL
		OR date_timeout <= @CurrenDate)
		AND (
		(to_ip = COALESCE(@ip, to_ip) AND cast(date_msg AS date) = CAST(@CurrenDate AS date))
		OR cast(date_msg AS date) < CAST(@CurrenDate AS date) 
		OR to_ip IS NULL) 

	IF @@rowcount > 0
	BEGIN
		UPDATE M 
		SET receive = current_timestamp
		FROM dbo.MESSAGES_USERS AS M
		JOIN @t AS t
			ON M.id = t.id
	END

	IF @ip IS NOT NULL
		EXEC k_activity_3 @IpAddress1 = @ip

	SELECT
		*
	FROM @t

END
go

