CREATE   PROCEDURE [dbo].[k_PeopleFinShow]
(
	  @occ1 INT
	, @fin_id1 INT
	, @added1 BIT = 0 -- с учетом изменений,   1 - без изменений
	, @is_all BIT = NULL -- всех граждан проживающих когда-либо
)
AS
	/*
	  Выдаем список людей проживающих по заданному лиц. счету в заданном фин. периоде
	  может отличаться с данными на данный момент
	*/
	SET NOCOUNT ON

	CREATE TABLE #p1 (
		  fin_id SMALLINT
		, occ INT
		, owner_id INT NOT NULL
	    , people_uid UNIQUEIDENTIFIER NOT NULL 
		, lgota_id SMALLINT DEFAULT NULL
		, status_id TINYINT
		, status2_id VARCHAR(10) COLLATE database_default
		, birthdate SMALLDATETIME
		, doxod DECIMAL(9, 2) DEFAULT NULL
		, KolDayLgota TINYINT DEFAULT NULL
		, data1 SMALLDATETIME
		, data2 SMALLDATETIME
		, kolday TINYINT DEFAULT NULL
		, DateEnd SMALLDATETIME DEFAULT NULL
	)

	IF @is_all = 1
	BEGIN -- хотим показать всех граждан проживающих когда-либо
		INSERT INTO #p1
			(fin_id
		   , occ
		   , owner_id
		   , people_uid		   
		   , lgota_id
		   , status_id
		   , status2_id
		   , birthdate
		   , doxod
		   , KolDayLgota
		   , data1
		   , data2
		   , kolday
		   , DateEnd)
		SELECT NULL AS fin_id
			 , occ
			 , id
		     , people_uid
			 , NULL AS lgota_id
			 , status_id
			 , status2_id
			 , birthdate
			 , NULL as doxod
			 , NULL AS KolDayLgota
			 , p.DateReg AS data1
			 , p.DateDel AS data2
			 , NULL AS kolday
			 , p.DateEnd
		FROM dbo.People p
		WHERE p.occ = @occ1
	END
	ELSE
	BEGIN
		IF @added1 = 0
			INSERT INTO #p1 EXEC k_PeopleFin @occ1
										   , @fin_id1
		IF @added1 = 1
			INSERT INTO #p1 EXEC k_PeopleFin @occ1
										   , @fin_id1
										   , 1
	END

	SELECT CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') AS Initials
		 , p1.kolday
		 , CASE
               WHEN p1.lgota_id > 0 THEN p1.lgota_id
               ELSE NULL
        END AS lgota_id
		 , CONVERT(VARCHAR(10), p1.Birthdate, 104) AS birthdate
		 , SUBSTRING(st.name, 1, 15) AS status_id
		 , per.name AS status2_id
		 , CONVERT(VARCHAR(10), p.DateReg, 104) AS DateReg
		 , CONVERT(VARCHAR(10), p.DateDel, 104) AS DateDel
		 , CASE
			   WHEN p1.KolDayLgota <> 0 THEN p1.KolDayLgota
			   ELSE NULL
		   END AS KolDayLgota
		 , p1.owner_id AS owner_id
		 , CONVERT(VARCHAR(10), p1.DateEnd, 104) AS DateEnd
		 , P.Contact_info
	FROM #p1 AS p1
		JOIN dbo.People AS p ON 
			p1.owner_id = p.id
		JOIN dbo.Person_statuses AS per ON 
			p1.status2_id = per.id
		JOIN dbo.Status AS st ON 
			p1.status_id = st.id
	WHERE p1.occ = @occ1
go

