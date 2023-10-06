CREATE   PROCEDURE [dbo].[adm_show_user_tip]
(
	  @user_id1 SMALLINT
	, @access1 BIT = 1
)
AS
	/*
		Показываем список доступных типов фондов пользователю @access1 =1
		exec adm_show_user_tip 45,1
	*/
	SET NOCOUNT ON

	-- доступные
	IF @access1 = 1
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM dbo.Users_occ_types AS pa 
					JOIN dbo.Users AS u 
						ON pa.SYSUSER = u.login
					JOIN dbo.Occupation_Types AS ot 
						ON pa.ONLY_TIP_ID = ot.id
				WHERE u.id = @user_id1
			)
			SELECT pa.ONLY_TIP_ID AS ID
				 , ot.name
				 , pa.only_read
				 , pa.fin_id_start
				 , pa.SYSUSER
			FROM dbo.Users_occ_types AS pa 
				JOIN dbo.Users AS u 
					ON pa.SYSUSER = u.login
				JOIN dbo.Occupation_Types AS ot 
					ON pa.ONLY_TIP_ID = ot.ID
			WHERE u.ID = @user_id1

		ELSE
		BEGIN
			SELECT CAST(NULL AS SMALLINT) AS id
				 , CAST('Все типы' AS VARCHAR(50)) AS name
				 , CAST(NULL AS BIT) AS ONLY_READ
				 , CAST(NULL AS SMALLINT) AS fin_id_start
				 , CAST(NULL AS NVARCHAR(30)) AS SYSUSER
		END
	END
	ELSE
	BEGIN --  Показываем список не доступных типов жилого фонда пользователю @access1 = 0	
		SELECT ot.id
			 , ot.name
			 , CAST(NULL AS BIT) AS ONLY_READ
			 , CAST(NULL AS SMALLINT) AS fin_id_start
			 , CAST(NULL AS NVARCHAR(30)) AS SYSUSER
		FROM dbo.Occupation_Types AS ot
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Users_occ_types AS pa 
					JOIN dbo.Users AS u 
						ON pa.SYSUSER = u.login
					JOIN dbo.Occupation_Types AS ot2 
						ON pa.ONLY_TIP_ID = ot2.id
				WHERE u.id = @user_id1
					AND pa.ONLY_TIP_ID = ot.id
			)
	END
go

