-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE       PROCEDURE [dbo].[ws_FindFio]
(
	@last_name	 VARCHAR(50) = NULL
   ,@first_name	 VARCHAR(30) = NULL
   ,@second_name VARCHAR(30) = NULL
)
AS
	--
	--   Поиск людей по Ф.И.О
	--
	SET NOCOUNT ON;

	--print @last_name
	IF (@last_name IS NULL)
		OR (@last_name = '0')
		SET @last_name = ''
	IF (@first_name IS NULL)
		OR (@first_name = '0')
		SET @first_name = ''
	IF (@second_name IS NULL)
		OR (@second_name = '0')
		SET @second_name = ''

	DECLARE @ROW1 INT

	SET @ROW1 = 1000

	SELECT TOP (@ROW1)
		ROW_NUMBER() OVER (ORDER BY o.address) AS RowNumber
	   ,p.Id
	   ,p.occ
	   ,CAST(Del AS SMALLINT) AS Del
	   ,Last_name
	   ,First_name
	   ,Second_name
	   ,Lgota_id
	   ,s.name AS Status_name
	   ,ps.name AS Status2_name
	   ,fam.name AS Fam_name
	   ,Birthdate AS Birthdate
	   ,DateReg AS DateReg
	   ,DateDel AS DateDel
	   ,DateDeath AS DateDeath
	   ,CAST(COALESCE(sex, 0) AS SMALLINT) AS sex
	   ,o.address
	FROM dbo.PEOPLE AS p 
	JOIN dbo.OCCUPATIONS AS o 
		ON p.occ = o.occ
	JOIN dbo.FAM_RELATIONS AS fam
		ON p.id = fam.Id
	JOIN dbo.STATUS AS s
		ON p.status_id = s.Id
	JOIN dbo.PERSON_STATUSES AS ps
		ON p.Status2_id = ps.Id
	WHERE Last_name LIKE @last_name + '%'
	AND First_name LIKE @first_name + '%'
	AND Second_name LIKE @second_name + '%'
	ORDER BY o.address
go

