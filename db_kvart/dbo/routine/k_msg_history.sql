-- =============================================
-- Author:		Пузанов
-- Create date: 11.01.2013
-- Description:	Выдаём историю сообщений пользователя
-- =============================================
CREATE     PROCEDURE [dbo].[k_msg_history]
(
	@msg_to	   SMALLINT	   = 1 -- 1-выдать только отправленные сообщения, 2- только полученные, 3-все
   ,@sysuser   VARCHAR(30) = NULL-- логин текущего пользователя
   ,@count_row SMALLINT	   = 50
)
AS
/*
k_msg_history 2
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CurrenDate SMALLDATETIME = current_timestamp

	IF @sysuser IS NULL
		SET @sysuser = system_user
	IF @msg_to IS NULL
		SET @msg_to = 1
	IF @count_row IS NULL
		SET @count_row = 50

	SELECT TOP (@count_row)
		m.id
	   ,m.date_msg
	   ,u.Initials AS to_user
	   ,m.[receive] AS date_receive
	   ,m.date_timeout
	   ,m.to_login
	   ,m.to_ip
	   ,CAST(m.from_login AS VARCHAR(30)) AS from_login
	   ,(SELECT
				u2.Initials
			FROM dbo.USERS AS u2 
			WHERE m.from_login = u2.login)
		AS from_user
	   ,m.from_ip
	   ,m.msg_text -- REPLACE(msg_text, CHAR(10), ' ') AS msg_text -- убираем перевод строки
	   ,m.id_parent
	   ,dbo.Fun_GetOnlyDate(m.date_msg) AS data_msg
	   ,CONVERT(VARCHAR(15), m.date_msg, 114) AS time_msg  -- тип TIME не использую на XP не понимает
	   ,m.FileName_msg
	--INTO #t_msg
	FROM dbo.MESSAGES_USERS AS m 
	JOIN dbo.USERS AS u 
		ON m.to_login = u.login
	WHERE ((m.from_login = @sysuser
	OR @sysuser IS NULL)
	OR (to_login = @sysuser
	OR @sysuser IS NULL))
	AND (
	(@msg_to = 1
	AND m.from_login = @sysuser) -- 1-выдать только отправленные сообщения
	OR
	(@msg_to = 2
	AND m.to_login = @sysuser -- 2- только полученные
	OR (m.from_login = @sysuser
	AND m.id_parent > 0))
	OR @msg_to = 3
	)
	--ORDER BY date_msg DESC
	ORDER BY CASE
		WHEN @msg_to = 1 THEN m.date_msg
		WHEN @msg_to = 2 THEN m.receive
		ELSE m.date_msg
	END DESC

END
go

