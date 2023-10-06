CREATE   PROCEDURE [dbo].[rep_fio]
(
	@occ1	  INT
   ,@Del	  BIT = 0 -- Только те кто проживает
   ,@status2  BIT = 0 -- 1 -только постоянная прописка
   ,@fam_show BIT = 1
)
AS
	/*
		
		 Показываем список людей на заданном лицевом 
		
	EXEC [rep_fio] 680000023,0,0,0
	EXEC [rep_fio] 700010027,0,0,0

	*/
	SET NOCOUNT ON


	IF @fam_show IS NULL
		SET @fam_show = 1

	SELECT
		p.id
	   ,p.FIO
	   ,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Д', CASE
                                                                       WHEN p.sex = 1 THEN 'МУЖ'
                                                                       ELSE CASE
                                                                                WHEN p.sex = 0 THEN 'ЖЕН'
                                                                                ELSE NULL
                                                                           END
        END)    AS FIOdat
	   ,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Р', CASE
                                                                       WHEN p.sex = 1 THEN 'МУЖ'
                                                                       ELSE CASE
                                                                                WHEN p.sex = 0 THEN 'ЖЕН'
                                                                                ELSE NULL
                                                                           END
        END)    AS FIOrod
	   ,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Т', CASE
                                                                       WHEN p.sex = 1 THEN 'МУЖ'
                                                                       ELSE CASE
                                                                                WHEN p.sex = 0 THEN 'ЖЕН'
                                                                                ELSE NULL
                                                                           END
        END)    AS FIOtvor
	   ,p.Birthdate
	   ,p.DateReg
	   ,p.DateDel
	   ,ps.name AS pstatus_name
	   ,CASE ps.is_temp
			WHEN '0' THEN 'Постоянно'
			WHEN '1' THEN 'Временно'
			ELSE ''
		END     AS pasport_status_name
	   ,O.[address]
	   ,IT.name AS DOC_NAME
	   ,I.DOCTYPE_ID
	   ,I.doc_no
	   ,I.PASSSER_NO
	   ,I.ISSUED
	   ,I.DOCORG
	   ,I.user_edit
	   ,I.date_edit
	   ,I.kod_pvs
	   ,CASE
			WHEN @fam_show = 0 THEN ''
			WHEN p.Fam_id = '????' THEN ''
			ELSE FR.name
		END AS Fam_name
	FROM dbo.VPeople AS p 
	JOIN dbo.Person_statuses AS ps 
		ON p.Status2_id = ps.id
	JOIN dbo.Occupations AS O 
		ON p.Occ = O.Occ
	LEFT JOIN dbo.Iddoc AS I 
		ON p.id = I.owner_id
		AND I.active = 1
	LEFT JOIN dbo.Iddoc_types AS IT 
		ON I.DOCTYPE_ID = IT.id
	LEFT JOIN dbo.Fam_relations FR 
		ON p.Fam_id = FR.id
	WHERE p.Occ = @occ1
	AND Del =
		CASE
			WHEN @Del = 0 THEN 0 -- только проживающие на данный момент 
			ELSE Del -- все
		END
	AND Status2_id =
		CASE
			WHEN @status2 = 1 THEN 'пост' -- только с постоянной пропиской
			ELSE Status2_id -- все
		END
go

