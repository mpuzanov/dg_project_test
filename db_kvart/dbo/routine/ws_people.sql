-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE       PROCEDURE [dbo].[ws_people]
(
	@occ INT
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		ROW_NUMBER() OVER (ORDER BY DateDel) AS RowNumber
		,p.id
		,p.occ
		,CONVERT(SMALLINT, Del) AS Del
		,last_name
		,first_name
		,second_name
		,lgota_id
		,STATUS.Name AS Status_name
		,ps.Name AS Status2_name
		,fam.Name AS Fam_name
		,Birthdate AS Birthdate
		,DateReg AS DateReg
		,DateDel AS DateDel
		,DateDeath AS DateDeath
		,CAST(COALESCE(sex, 0) AS SMALLINT) AS sex
		,o.address
	FROM	dbo.PEOPLE AS p 
			,dbo.FAM_RELATIONS AS fam
			,dbo.STATUS
			,dbo.PERSON_STATUSES AS ps
			,dbo.OCCUPATIONS AS o
	WHERE p.occ = @occ
	AND p.Fam_id = fam.id
	AND p.status_id = STATUS.id
	AND p.status2_id = ps.id
	AND p.occ = o.occ
	ORDER BY DateDel
END
go

