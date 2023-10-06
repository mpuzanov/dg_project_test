CREATE   PROCEDURE [dbo].[k_intPrintDetail_serv]
( @fin_id1 SMALLINT, -- Фин.период
  @occ1 INT,  -- лицевой
  @service_id1 VARCHAR(10)  -- услуга
)
AS
--
--  Печать информации о начислении по 1 услуге в счете-квитанции     
--
SET NOCOUNT ON
 
DECLARE @fin_current1 SMALLINT
SELECT @fin_current1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

IF @fin_id1>=@fin_current1
BEGIN
 SELECT p.occ,
        s.short_name,
		u.short_id,	
		p.service_id,
		p.tarif,
        p.saldo,
        p.paymaccount,
        p.paymaccount_peny,
		p.value AS fullvalue,
		p.value,
		0 AS discount, --p.discount,
		p.added,
		0 AS compens, --p.compens,
		p.paid,
        p.debt
 FROM paym_list AS p  , 
		services AS s  , 
		service_units AS su ,
		units AS u ,
        OCCUPATIONS AS o 
 WHERE (p.occ=@occ1) 
      AND p.occ=o.occ
      AND (s.id=@service_id1)
      AND (p.service_id=s.id) 
      AND (s.id=su.service_id) 
      AND (su.roomtype_id=o.roomtype_id) 
      AND (su.fin_id=@fin_id1)
      AND (su.unit_id=u.id) 
      AND su.tip_id=o.tip_id
      AND (p.subsid_only=0)
      AND p.account_one=1
END
ELSE
BEGIN
 
 DROP TABLE IF EXISTS #t;

 SELECT p.occ,
        s.short_name,
		u.short_id,	
		p.service_id,
		p.tarif,
		p.saldo,
		p.paymaccount,
		p.paymaccount_peny,
		p.value AS fullvalue,
		p.value,
		p.discount,
		p.added,
		p.compens,
		p.paid,
        p.debt
 INTO #t
 FROM paym_history AS p  , 
	  services AS s  , 
	  service_units AS su ,
	  units AS u  ,
      OCCUPATIONS AS o 
 WHERE p.fin_id=@fin_id1
      AND (p.occ=@occ1) 
      AND p.occ=o.occ
      AND (s.id=@service_id1)
      AND (p.service_id=s.id) 
      AND (s.id=su.service_id) 
      AND (su.roomtype_id=o.roomtype_id) 
      AND (su.fin_id=@fin_id1)
      AND (su.unit_id=u.id) 
      AND su.tip_id=o.tip_id
      AND (p.subsid_only=0)
      AND p.account_one=1

 IF NOT EXISTS(SELECT * FROM #t) 
 BEGIN
   INSERT INTO #t
   SELECT DISTINCT @occ1, s.short_name, 
	u.short_id,	
	s.id AS 'service_id',
	0 AS 'tarif',
    0 AS 'saldo',
    0 AS 'paymaccount',
    0 AS 'paymaccount_peny',
	0 AS 'fullvalue',
	0 AS 'value',
	0 AS 'discount',
	0 AS 'added',
	0 AS 'compens',
	0 AS 'paid',
    0 AS 'debt'
   FROM SERVICES AS s ,
	service_units AS su ,
	units AS u  
   WHERE s.id=@service_id1
      AND (s.id=su.service_id) 
      AND (su.roomtype_id='отдк') 
      AND (su.unit_id=u.id) 
      AND (su.tip_id=1) 
 END
 SELECT * FROM #t

END
go

