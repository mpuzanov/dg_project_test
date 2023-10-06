CREATE   PROCEDURE [dbo].[k_raschet_1] 
( @occ1 INT,
  @fin_id1 SMALLINT = NULL -- Код финансового периода за который надо сделать расчет
  ,@added SMALLINT = 0  --  0 - расчет за текущий фин. период
                       --  1 - расчет за прошлые фин. периоды
                       --  2 - разовые (некачественное предоставление услуг и недопоставка) 
                       --  3 - для расчета субсидий как @added=0 только 
                       --  кидаем суммы в PAYM_ADD 
  ,@data1 DATETIME = NULL    -- начальная дата
  ,@data2 DATETIME = NULL    -- конечная дата для перерасчетов
  ,@tnorm1 SMALLINT = 0       -- нормативная температура
  ,@tnorm2 SMALLINT = 0       -- насколько градусов меньше
  ,@alladd SMALLINT = 0       -- 1-общий перерасчет
  ,@lgotadayno SMALLINT =0    -- Не использовать расчет льготы по дням
  ,@people_list BIT = 0      -- заносить расширенную информацию по расчету в PEOPLE_LIST_RAS
  ,@serv_one1 VARCHAR(10) = NULL -- если надо расчитать только эту услугу 
  ,@mode_history BIT = 0     -- при перерасчетах режимы брать из истории
  ,@total_sq_new DECIMAL(10, 4) = NULL  -- расчитать на эту площадь
  ,@debug BIT =0
)
--WITH ENCRYPTION

AS
/*
--
--  Процедура расчета квартплаты по заданному лицевому счету
--

дата создания: 
автор: Пузанов М.А.

дата последней модификации: 28.02.09
автор изменений: Пузанов М.А.

Какие изменения были:

*/ 

SET NOCOUNT ON
SET XACT_ABORT ON

SET LOCK_TIMEOUT 5000 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

EXECUTE [dbo].[k_raschet_2] 
   @occ1
  ,@fin_id1
  ,@added
  ,@data1
  ,@data2
  ,@tnorm1
  ,@tnorm2
  ,@alladd
  ,@lgotadayno
  ,@people_list
  ,@serv_one1
  ,@mode_history
  ,@total_sq_new
  ,@debug
RETURN 0
go

