CREATE   PROCEDURE [dbo].[k_people_schtl_all]
(
	@occ1 INT
)
AS
	/*
	
	Список всех людей на лицевом счете
	
	*/
	SET NOCOUNT ON


	SELECT
		p.id
		,p.last_name
		,p.first_name
		,p.second_name
		,ps.Name AS status2_id
		,p.lgota_id
		,p.birthdate
		,p.DateReg
		,p.DateDel
		,p.DateDeath
		,p.Del
		,p.DateEnd
	FROM dbo.PEOPLE AS p
	JOIN dbo.PERSON_STATUSES AS ps 
		ON p.status2_id = ps.id
	WHERE p.occ = @occ1
	ORDER BY p.Del, p.DateReg
go

