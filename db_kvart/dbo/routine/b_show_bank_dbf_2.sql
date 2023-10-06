CREATE   PROCEDURE [dbo].[b_show_bank_dbf_2]
(
	@data1		DATE
   ,@data2		DATE
   ,@bank1		INT	   = NULL -- или код банка или код платежа
   ,@filtr		BIT	   = 0-- 1 - сортировка по банку с 1-м разрешением ext, -- 0 - сортировка по всему банку
   ,@DBF_TIP	SMALLINT = 1
   ,@isdouble	BIT	   = 0		--для прверки повторяющихся лицевых
   ,@datavvoda	SMALLDATETIME = NULL  -- дата загрузки реестра в БД
)
AS
	/*
	Выборка по таблице BANK_DBF
	
	exec b_show_bank_dbf_2 '20201201','20210301',NULL,NULL,1,1
	exec b_show_bank_dbf_2 '20201201','20210301',NULL,NULL,1,1,'20210111'
	   
	*/

	SET NOCOUNT ON

	IF @DBF_TIP IS NULL
		SET @DBF_TIP = 1
	IF @isdouble IS NULL
		SET @isdouble = 0
	IF @filtr IS NULL
		SET @filtr = 0

	DECLARE @t TABLE
		(
			ext VARCHAR(10) PRIMARY KEY
		)

	IF @filtr = 0

		INSERT @t
			SELECT DISTINCT
				po.ext
			FROM dbo.View_PAYCOLL_ORGS AS po
			WHERE (po.BANK = @bank1
			OR @bank1 IS NULL)

	ELSE

		INSERT @t
			SELECT DISTINCT
				po.ext
			FROM dbo.View_PAYCOLL_ORGS AS po 
			WHERE (po.id = @bank1
			OR @bank1 IS NULL)
	--SELECT * from @t

	--IF @DBF_TIP = 1
	SELECT
		t.*
	   ,o.status_id
	   ,vb.adres AS adres_dom
	   ,ot.name AS tip_name
	   ,s.name AS sup_name
	   ,bc.comments
	FROM (SELECT
			BD.id
		   ,bs.datafile AS DATA_PAYM
		   ,CAST(bs.datavvoda AS DATE) AS datavvoda
		   ,BD.bank_id
		   ,BD.sum_opl
		   ,BD.pdate
		   ,BD.grp
		   ,BD.occ
		   ,BD.service_id
		   ,BD.sch_lic
		   ,BD.pack_id
		   ,BD.p_opl
		   ,BD.adres
		   ,BD.date_edit
		   ,BD.filedbf_id
		   ,BD.sup_id
		   ,BD.commission
		   ,CASE
				WHEN BD.sum_opl > 0 THEN CAST(ROUND(BD.commission / BD.sum_opl * 100, 1) AS DECIMAL(9, 1))
				ELSE 0
			END AS Proc_commission
		   ,bs.FILENAMEDBF
		   ,BD.rasschet
		   ,BD.error_num
		   ,bs.datafile
		   ,COUNT(COALESCE(BD.occ,0)) OVER (PARTITION BY BD.occ, BD.sum_opl, bs.datafile) AS kol_occ
		   ,BD.fio
		FROM dbo.BANK_DBF AS BD 
		JOIN dbo.View_BANK_TBL_SPISOK AS bs 
			ON BD.filedbf_id = bs.filedbf_id
		JOIN @t AS po
			ON bs.bank_id = po.ext
		WHERE bs.datafile BETWEEN @data1 AND @data2
		AND bs.dbf_tip = CASE
                             WHEN @DBF_TIP > 2 THEN bs.dbf_tip
                             ELSE @DBF_TIP
            END) AS t
	LEFT JOIN dbo.BANKDBF_COMMENTS AS bc
		ON t.id = bc.id
	LEFT JOIN dbo.OCCUPATIONS AS o 
		ON t.occ = o.occ
	LEFT JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	LEFT JOIN dbo.View_BUILDINGS_LITE AS vb
		ON f.bldn_id = vb.id
	LEFT JOIN dbo.OCCUPATION_TYPES AS ot
		ON o.tip_id = ot.id
	LEFT JOIN dbo.SUPPLIERS_ALL AS s 
		ON t.sup_id = s.id
	WHERE (@isdouble = 0
		OR (@isdouble = 1 -- Показываем только дубли
		AND t.kol_occ > 1))
		AND (@datavvoda is NULL OR t.datavvoda=@datavvoda)
	ORDER BY datafile
	OPTION (RECOMPILE)
go

