CREATE   PROCEDURE [dbo].[k_komp_save] 
( @occ1 INT,
  @added1 BIT=0,  -- добавление субсидии как разовых
  @owner_id1 INT=NULL, -- Получатель субсидии (код человека) --
  @ras1 BIT = 0 -- Сохранять субсидию с перерасчетом
)
AS
--
--  Временну компенсацию заносим в постоянную
--  compensac_tmp -> compencas
--  comp_serv_tmp -> comp_serv
--
 
SET NOCOUNT ON


IF dbo.Fun_AccessSubsidLic(@occ1)=0
BEGIN
   RAISERROR('Для Вас работа с Субсидиями запрещена',16,1)
   RETURN
END

DECLARE @fin_id1 SMALLINT, @err INT,
        @DateRaschet SMALLDATETIME, @DateNazn1 SMALLDATETIME,
        @id1 INT, @idDel INT, @DateStart SMALLDATETIME,
        @SumKomp DECIMAL(10, 4), @koef REAL, @Doxod DECIMAL(15,2),
        @DateEnd SMALLDATETIME, @dateEndFin SMALLDATETIME
 
SELECT  @DateRaschet=DateRaschet, 
        @DateNazn1=DateNazn,
        @DateEnd=DateEnd,
        @SumKomp =SumKomp,  
        @koef=koef,
        @Doxod=Doxod
FROM  dbo.compensac_tmp  
WHERE occ=@occ1
 
IF (@SumKomp=0) OR (@SumKomp IS NULL)
BEGIN
     RAISERROR ('Компенсация не положена',16,1)
     RETURN 1
END
 
IF @Doxod=0
BEGIN
     RAISERROR ('Доход не может быть равен 0 ',16,1)
     RETURN 1
END


SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

SELECT @DateStart=start_date, 
       @dateEndFin=end_date 
FROM dbo.global_values  WHERE fin_id=@fin_id1
 
IF @DateEnd<@dateEndFin
BEGIN
   RAISERROR ('Срок окончания уже прошел! Лицевой: %d',16,1,@occ1)
   RETURN 1
END

BEGIN TRAN    
 
IF @added1=0
BEGIN
    EXEC k_komp_delete @occ1, @ras1=0
    
    ---exec @id1=k_komp_next
 
    INSERT INTO dbo.compensac_ALL 
    (fin_id,occ, dateRaschet, dateNazn, dateEnd, sumkomp, sumkomp_noext, 
     sumkvart, sumnorm, doxod, metod, kol_people, realy_people, 
     koef, avto, finperiod, transfer_bank, comments, owner_id,sum_pm)
    SELECT  
     @fin_id1, occ, dateRaschet, dateNazn, dateEnd, sumkomp, sumkomp_noext, 
     sumkvart, sumnorm, doxod, metod, kol_people, realy_people,
     koef, avto, finperiod, transfer_bank, comments, @owner_id1, sum_pm
    FROM compensac_tmp AS ct  WHERE occ=@occ1
    
    SELECT @id1=SCOPE_IDENTITY()
 
    INSERT INTO dbo.comp_serv_ALL  
    (fin_id, occ, service_id, tarif, value_socn, value_paid, value_subs, subsid_norma) 
    SELECT @fin_id1, occ, service_id, tarif, value_socn, value_paid, value_subs, subsid_norma
    FROM comp_serv_tmp AS cst  WHERE occ=@occ1
     
    IF NOT EXISTS(SELECT occ FROM dbo.compensac_all WHERE occ=@occ1 and fin_id=@fin_id1)
    BEGIN
      ROLLBACK TRAN
      RAISERROR ('Ошибка добавления Компенсации',16,1)
      RETURN 1
    END

END
 
IF @added1=1
BEGIN
-- Добавляем разовые по субсидиям
  IF (@DateNazn1<@DateStart) 
  BEGIN
    DECLARE @kolmes TINYINT, @service_id1 VARCHAR(10), @summa1 MONEY
    SELECT @kolmes=DATEDIFF(MONTH,@DateNazn1,@DateStart)
    
    DECLARE curs CURSOR LOCAL FOR 
		SELECT service_id, value_subs FROM comp_serv_tmp WHERE occ=@occ1
    OPEN curs
    FETCH NEXT FROM curs INTO @service_id1, @summa1
    WHILE (@@FETCH_STATUS=0)
    BEGIN
       SET @summa1=-1*@summa1*@kolmes
 
       EXEC dbo.ka_add_subsid @occ1, @service_id1, @summa1, '', @owner_id1
 
       FETCH NEXT FROM curs INTO @service_id1, @summa1
     END --while
    CLOSE curs;
    DEALLOCATE curs;
  END --if
  ELSE
  BEGIN --удаляем разовые по субсидиям
    DELETE FROM dbo.added_payments 
    WHERE occ=@occ1 AND add_type=4
  END
 
END
 
COMMIT TRAN
 

-- Расчитываем квартплату
IF @ras1=1   EXEC @err=dbo.k_raschet_1 @occ1, @fin_id1
go

