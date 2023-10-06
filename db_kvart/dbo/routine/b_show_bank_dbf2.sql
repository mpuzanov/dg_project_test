CREATE   PROCEDURE [dbo].[b_show_bank_dbf2] (@filedbf_id INT
, @isdouble BIT = 0  --для прверки повторяющихся лицевых
)
AS
  /*
		--  Список платежей по файлу из BANK_DBF
	
		b_show_bank_dbf2 80258,1
	
	*/
  SET NOCOUNT ON

  IF @isdouble IS NULL
    SET @isdouble = 0

  SELECT
    *
  FROM (SELECT
      bd.id
     ,bd.bank_id
     ,bd.filedbf_id
     ,bd.sum_opl
     ,bd.pdate
     ,bd.occ
     ,bd.sch_lic
     ,bd.p_opl
     ,bd.adres
     ,bd.pack_id
     ,bd.service_id
     ,bd.grp
     ,bd.date_edit
     ,bd.sup_id
     ,bd.commission
     ,bd.dog_int
     ,bd.dbf_tip
     ,bd.rasschet
     ,bd.error_num
     ,bd.sysuser AS sysuser_bd
     ,bd.fio

     ,bs2.filenamedbf
     ,bs2.summa
     ,bs2.kol
     ,bs2.datavvoda
     ,bs2.datafile
     ,bs2.sysuser
     ,s.name AS sup_name
     ,o.status_id
     ,COUNT(bd.occ) OVER (PARTITION BY bd.occ, bd.sum_opl) AS kol_occ
    FROM dbo.BANK_DBF AS bd 
    JOIN dbo.[View_BANK_TBL_SPISOK] AS bs2
      ON bd.filedbf_id = bs2.filedbf_id
    LEFT JOIN dbo.SUPPLIERS_ALL AS s 
      ON bd.sup_id = s.id
    LEFT JOIN dbo.OCCUPATIONS AS o 
      ON bd.occ = o.occ
    WHERE bs2.filedbf_id = @filedbf_id) AS t
  WHERE (@isdouble = 0
  OR (@isdouble = 1 -- Показываем только дубли
  AND t.kol_occ > 1)
  )
go

