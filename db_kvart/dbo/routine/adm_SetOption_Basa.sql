CREATE   PROCEDURE [dbo].[adm_SetOption_Basa]
(
	@P1 SMALLINT
   ,@p2 BIT
)
AS
/*
  Установка режимов работы базы
  P1=1     dbo use only
  P1=2     single use
  P1=3     read only
*/
	SET NOCOUNT ON

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME());

	IF @p2 = 0
		EXECUTE ('
			USE [master]
			GO
			ALTER DATABASE ' + @DB_NAME + ' SET MULTI_USER;
			GO
			')
	ELSE
	BEGIN
		IF @P1 = 1
		BEGIN
			-- dbo use only
			EXECUTE ('
			USE [master]
			GO
			ALTER DATABASE ' + @DB_NAME + ' RESTRICTED_USER WITH NO_WAIT;
			GO
			')
		END
		IF @P1 = 2
		BEGIN
			-- single user
			EXECUTE ('
			USE [master]
			GO
			ALTER DATABASE ' + @DB_NAME + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
			GO
			')
		END
		IF @P1 = 3
		BEGIN
			-- read only
			EXECUTE ('
			USE [master]
			GO
			ALTER DATABASE ' + @DB_NAME + ' SET READ_ONLY WITH NO_WAIT;
			GO
			')
		END
	END

	SELECT
		'Result' = 0
go

