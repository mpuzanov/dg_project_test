CREATE   PROCEDURE [dbo].[k_pid_cessia] 
/*
k_pid_cessia 220037, 315
*/
( 
@occ INT,
@sup_id INT
)
AS
 
SET NOCOUNT ON

declare @occ_sup int

SELECT top 1 @occ_sup=occ_sup FROM dbo.OCC_SUPPLIERS where occ=@occ and sup_id=@sup_id order BY fin_id desc
--print @occ_sup
SELECT 
	--ces.occ_sup as 'Лицевой', 
	--ces.dolg_mes_start as 'Нач. глубина долга',
	--ces.saldo_start AS 'Начальный долг',
	ces.occ_sup, 
	ces.dolg_mes_start,
	ces.saldo_start,
	ces.debt_current,
	ces.cessia_dolg_mes_new,		
	dog.dog_date as 'Дата договора',
	dog.dog_name as 'Договор',
	dog.data_start as 'Дата нач.действия',	
	col.name as 'Коллектор', 
	cour.name as 'Судебный участок',
	dog.id AS 'Код договора'	
FROM dbo.CESSIA AS ces 
	JOIN dbo.View_OCC_ALL as o  ON ces.occ=o.occ	
	JOIN dbo.BUILDINGS as b ON o.bldn_id=b.id and o.fin_id=b.fin_current
	LEFT JOIN dbo.COLLECTORS as col ON b.collector_id=col.id
	LEFT JOIN dbo.COURTS as cour  ON b.court_id=cour.id
	LEFT JOIN dbo.DOG_SUP as dog  ON ces.dog_int=dog.id
WHERE ces.occ_sup=@occ_sup
AND o.occ=@occ
go

