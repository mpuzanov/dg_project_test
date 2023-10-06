CREATE   FUNCTION [dbo].[Fun_Initials_StrPeople]
(
	@occ1		INT
	,@Fin_id1	SMALLINT
)
RETURNS VARCHAR(200)

AS

BEGIN
	/*
	инициалы всех зарегестрированных на лицевом счете
	
	select dbo.Fun_Initials_StrPeople(680000000,180)
	*/

	DECLARE @Initials VARCHAR(200) = ''

	SELECT
		@Initials = STUFF((SELECT
				CONCAT(', ' , RTRIM(Last_name) , ' ' , SUBSTRING(RTRIM(First_name), 1, 1) , '.' , SUBSTRING(RTRIM(Second_name), 1, 1) , '.')
			FROM dbo.View_people_all AS p
			WHERE p.occ = @occ1
			AND fin_id = @Fin_id1
			FOR XML PATH (''))
		, 1, 2, '')

	IF COALESCE(@Initials,'') = ''
	BEGIN
		SELECT @Initials = STUFF((SELECT
				CONCAT(', ' , CONCAT(RTRIM(p.[Last_name]),' ',LEFT(p.[First_name],1),'.',LEFT(p.Second_name,1),'.'))
			FROM dbo.People AS p 
			WHERE p.occ = @occ1
			FOR XML PATH (''))
		, 1, 2, '')

	END
	RETURN @Initials

END
go

