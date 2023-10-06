CREATE   PROCEDURE [dbo].[rep_flatcard2]
(
	  @occ1 INT = NULL
	, @DelTrue BIT = 0
	, @status2 BIT = 0 -- статус прописки, 0-все статусы, 1-постоянная (people.status_id='пост')
	, @flat_id1 INT = NULL

)
AS
	/*
	 Выдаем вторую часть информации для поквартирной карточки
	 Информацию по людям на лицевом счете
	
	 exec rep_flatcard2 @occ1=177028, @flat_id1=79948
	 exec rep_flatcard2 @occ1=null, @flat_id1=79948

	*/
	SET NOCOUNT ON

	IF @occ1 IS NULL
		AND @flat_id1 IS NULL
		SET @occ1 = 0

	SELECT p.id
		 , p.FIO AS FIO
		 , CASE p.Fam_id
			   WHEN '????' THEN ''
			   ELSE f.name
		   END AS Fam
		 , p.Birthdate
		 , p.DateReg
		 , CASE
               WHEN ps.is_temp = '1' THEN COALESCE(p.DateDel, p.DateEnd)
               ELSE p.DateDel
        END AS DateDel
		 , CASE
			   WHEN f.id = 'отвл' AND
				   DateDel IS NULL THEN 0
			   WHEN DateDel IS NULL THEN 1
			   ELSE 2
		   END AS sort
		 , p.Dola_priv
		 , p.Status2_id
		 , ps.name AS pstatus_name
		 , CASE ps.is_temp
			   WHEN '0' THEN 'Постоянно'
			   WHEN '1' THEN 'Временно'
			   ELSE ''
		   END AS pasport_status_name
	FROM dbo.VPeople AS p
		JOIN dbo.Occupations o ON 
			p.Occ = o.Occ
		JOIN dbo.Fam_relations AS f ON 
			p.Fam_id = f.id
		JOIN dbo.Person_statuses AS ps ON 
			p.Status2_id = ps.id
	WHERE 
		(@occ1 IS NULL OR p.Occ = @occ1)
		AND (@flat_id1 IS NULL OR o.flat_id = @flat_id1)
		AND p.Del = CASE WHEN @DelTrue = 0 THEN CAST(0 AS BIT) ELSE p.Del END
		AND p.Status2_id = CASE WHEN @status2 = 1 THEN 'пост' ELSE p.Status2_id  END
		AND ps.is_registration= CASE
                                    WHEN @status2 = 1 THEN CAST(1 AS BIT)
                                    ELSE ps.is_registration
								END -- 09/09/2021
	ORDER BY sort
		   , p.DateDel DESC
	OPTION(RECOMPILE)
go

