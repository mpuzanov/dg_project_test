CREATE   FUNCTION [dbo].[Fun_InitialsPrivat]
(
	@occ1		INT
	,@is_child	BIT	= 0 -- выводить детей
)
RETURNS VARCHAR(120)
AS
BEGIN
	/*
ФИО собственников на лицевом счёте

SELECT [dbo].[Fun_InitialsPrivat](235956,1)
SELECT [dbo].[Fun_InitialsPrivat](76627,1)
SELECT [dbo].[Fun_InitialsPrivat](700073814,0)
SELECT [dbo].[Fun_InitialsPrivat](680000572,0)
SELECT [dbo].[Fun_InitialsPrivat](680000571,0)
	
Дата изменения: 16.03.13
Автор изменения: Пузанов М.А.
*/
	IF @is_child IS NULL
		SET @is_child = 0

	DECLARE	@Initials			VARCHAR(200)
			,@kol_people		SMALLINT = 4

	IF @is_child = 1 -- вывод с детьми
	BEGIN
		SELECT
			@Initials = STUFF((SELECT TOP (@kol_people)
					', ' + CONCAT(RTRIM(Last_name), ' ', RTRIM(First_name), ' ', RTRIM(Second_name))
				FROM dbo.PEOPLE AS p
				WHERE p.occ = @occ1
					AND (Dola_priv1>0
						OR Status2_id = 'влпр')
					AND Del = 0
				ORDER BY Birthdate
				FOR XML PATH (''))
			, 1, 2, '')
	END
	ELSE
	BEGIN
		SELECT
			@Initials = STUFF((SELECT TOP (@kol_people)
					', ' + CONCAT(RTRIM(Last_name), ' ', RTRIM(First_name), ' ', RTRIM(Second_name))
				FROM dbo.PEOPLE AS p
				WHERE p.occ = @occ1
					AND (Dola_priv1>0
						OR Status2_id = 'влпр')
					AND Del = 0
					AND DATEDIFF(YEAR, Birthdate, current_timestamp) > 17
				ORDER BY Birthdate
				FOR XML PATH (''))
			, 1, 2, '')
	END
	IF @Initials IS NULL SELECT @Initials = '-'

	RETURN SUBSTRING(@Initials, 1, 120)

END
go

