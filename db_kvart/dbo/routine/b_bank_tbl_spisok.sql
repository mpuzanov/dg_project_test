CREATE   PROCEDURE [dbo].[b_bank_tbl_spisok]
(
	  @data1 DATE = NULL
	, @data2 DATE = NULL
	, @bank1 INT = NULL
	, @filtr BIT = 0  -- 1-сортировка по банку с разрешением ext, 0- сортировка по всему банку
	, @DBF_TIP SMALLINT = 1
	, @datavvoda1 DATE = NULL
	, @datavvoda2 DATE = NULL
)
AS
	/*
		Показываем список файлов по фильтру (для программы: Платежи)
		exec b_bank_tbl_spisok '20210401','20210420',null,1,1,'20210420','20210429'
		exec b_bank_tbl_spisok '20210301','20210328',null,0,2
	*/
	SET NOCOUNT ON

	IF @DBF_TIP IS NULL
		SET @DBF_TIP = 1

	DECLARE @date_default DATETIME
	SET @date_default = current_timestamp - 8 -- последняя неделя
	-- ставим конец дня
	DECLARE @data_end DATETIME = dbo.Fun_GetDateEnd(@data2)

	IF @datavvoda1 IS NOT NULL
	BEGIN
		SELECT @data1 = NULL
			 , @data_end = NULL
			 , @date_default = '20200101'
		IF @datavvoda2 IS NULL
			SET @datavvoda2 = @datavvoda1
	END

	SELECT BS.filenamedbf
		 , BS.datafile
		 , BS.bank_id
		 , BS.datavvoda
		 , BS.forwarded
		 , BS.kol
		 , BS.summa
		 , bdf.sum_error                    AS sum_error
		 , bdf.count_error                  AS count_error
		 , bdf.sum_pack                     AS sum_pack
		 , t2.bank_name                     AS name_bank
		 , t2.vid_paym_name
		 , BS.filedbf_id
		 , BS.commission
		 , COALESCE(U.Initials, BS.SYSUSER) AS sysuser
		 , BS.rasschet
		 , BS.format_name
		 , CAST(CASE
                    WHEN bdf.sup_id > 0 THEN 1
                    ELSE 0
        END AS BIT)                         AS sup_exist -- есть поставщик в реестре
	FROM dbo.View_bank_tbl_spisok AS BS 
		LEFT JOIN dbo.Users AS U ON BS.SYSUSER = U.[login]
		OUTER APPLY (
			SELECT SUM(CASE
					   WHEN bd.occ IS NULL THEN bd.sum_opl
					   ELSE 0
				   END) AS sum_error
				   ,SUM(CASE
					   WHEN bd.occ IS NULL THEN 1
					   ELSE 0
				   END) AS count_error
				 , SUM(CASE
					   WHEN bd.pack_id IS NOT NULL THEN bd.sum_opl
					   ELSE 0
				   END) AS sum_pack
				, MAX(bd.sup_id) AS sup_id
			FROM dbo.Bank_Dbf AS bd 
			WHERE bd.filedbf_id = BS.filedbf_id
		) AS bdf
		JOIN (
			SELECT DISTINCT po.ext
						  , b.short_name AS bank_name
						  , '' AS vid_paym_name  --pt.name AS vid_paym_name
			FROM dbo.Paycoll_orgs AS po 
				JOIN dbo.Paying_types pt ON po.vid_paym = pt.id
				INNER JOIN dbo.Bank AS b ON po.Bank = b.id
			WHERE po.Bank BETWEEN COALESCE(@bank1, 0) AND COALESCE(@bank1, 10000)
		) AS t2 ON BS.bank_id = t2.ext
	WHERE datafile BETWEEN COALESCE(@data1, @date_default) AND COALESCE(@data_end, '20500101')
		AND BS.dbf_tip = CASE
                             WHEN @DBF_TIP > 2 THEN BS.dbf_tip
                             ELSE @DBF_TIP
        END
		AND ((BS.datavvoda BETWEEN @datavvoda1 AND @datavvoda2) OR @datavvoda1 IS NULL)
	ORDER BY BS.datafile
go

