CREATE   PROCEDURE [dbo].[ka_add_people_history]
(
	@occ1		INT
	,@fin_id1	SMALLINT
)
AS
	--
	--  Выводим список людей по которым проводились начисления в 
	--  заданном фин. периоде и лицевом счете
	--
	SET NOCOUNT ON;

	CREATE TABLE #p1
	(
		fin_id			SMALLINT
		,occ			INT
		,owner_id		INT
	    ,people_uid     UNIQUEIDENTIFIER not null 
		,lgota_id		SMALLINT
		,status_id		TINYINT
		,status2_id		VARCHAR(10) COLLATE database_default
		,birthdate		SMALLDATETIME
		,doxod			DECIMAL(9, 2)
		,koldaylgota	TINYINT
		,data1			SMALLDATETIME
		,data2			SMALLDATETIME
		,kolday			TINYINT
		,DateEnd		SMALLDATETIME
	)
	INSERT INTO #p1 EXEC k_PeopleFin	@occ1
										,@fin_id1
										,1

	SELECT
		CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') AS Initials
		,p1.kolday
		,p1.lgota_id
		,CONVERT(VARCHAR(10), p1.Birthdate, 104) AS Birthdate
		,SUBSTRING(st.name, 1, 15) AS status_id
		,per.name as status2_id
		,CONVERT(VARCHAR(10), p1.data1, 104) AS DateReg
		,CONVERT(VARCHAR(10), p1.data2, 104) AS DateDel
		,p1.koldaylgota AS koldaylgota
		,p1.owner_id AS owner_id
	FROM dbo.People AS p 
	JOIN #p1 AS p1
		ON p.id = p1.owner_id
	JOIN dbo.Person_statuses AS per
		ON p1.status2_id = per.id
	JOIN dbo.Status AS st 
		ON p1.status_id = st.id
	WHERE p.occ = @occ1
go

