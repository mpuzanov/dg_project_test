CREATE   PROCEDURE [dbo].[k_penalty_show]
(  @occ1 int   
)
AS
--
--  Показывает суммы по пени 
--                             !!!!!!!!!!! старое
--
 
SET NOCOUNT ON
SET LANGUAGE RUSSIAN
 
select top(12)
fin_id=0,
'strmes'='', --Фин.период
'paid'=0.0,   --Начислено
'saldo'=0.0,   -- Исх.Сальдо
'paymvalue'=0.0, --Оплатил
'ostatok'=0.0, --Остаток
'doplata'=0.0, --Доплата
'ostatok2'=0.0, --Остаток2
'procent'=0.0, --Процент
'data_end'=convert(char(12),CURRENT_TIMESTAMP,106), --Посл.день
'LastDayPaym'=convert(char(12),CURRENT_TIMESTAMP,106), --День оплаты
'kolday'=0, --Кол.дней
'penalty_value'=0.0, --Пени
'pereplata'=0.0,  --Переплата
'peny_old_new'=0.0
go

