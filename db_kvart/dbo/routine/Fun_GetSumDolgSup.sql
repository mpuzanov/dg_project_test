CREATE   FUNCTION [dbo].[Fun_GetSumDolgSup] (@occ1 INT, @fin_current SMALLINT, @data1 SMALLDATETIME, @LastDatePaym SMALLDATETIME, @sup_id INT)  
RETURNS DECIMAL(9,2) AS  
BEGIN 
/*
ДЛЯ РАСЧЁТА ПЕНИ
Возвращаем сумму долга по единой квитанции на заданную дату

select dbo.Fun_GetSumDolgSup(216462,123,'20120329','20120410',300)
дата: 29.03.12
*/

	DECLARE 
		@res DECIMAL(9,2)=0,
		@sum_pay DECIMAL(9,2)=0,
		@fin_id SMALLINT,
		@start_date SMALLDATETIME,
		@day TINYINT
		
	SET @day=DAY(@LastDatePaym)
 	
 	IF @day=1 
	BEGIN				
		IF @data1<@LastDatePaym 
			SET @fin_id=@fin_current-2 
		ELSE 
			SET @fin_id=@fin_current-1
	END
	
	IF (@day>1 AND @day<31) 
	BEGIN
		IF @data1<@LastDatePaym 
			SET @fin_id=@fin_current-1 
		ELSE 
			SET @fin_id=@fin_current
	END
	
	IF (@day<1 OR @day>31) SET @fin_id=@fin_current
	 
	SELECT @sum_pay=SUM(p.value-coalesce(p.paymaccount_peny,0))
	FROM dbo.PAYINGS AS p 
		JOIN dbo.PAYDOC_PACKS AS pd 
			ON pd.id=p.pack_id
		JOIN dbo.PAYCOLL_ORGS as po 
			ON pd.fin_id=po.fin_id AND pd.source_id=po.id
		JOIN dbo.PAYING_TYPES as pt 
			ON po.vid_paym=pt.id    
	WHERE pd.fin_id>=@fin_id
			 AND p.occ=@occ1
			 AND p.sup_id=@sup_id
			 AND pd.day<=@data1
			 AND p.forwarded=cast(1 as bit)
			 AND pt.peny_no=cast(0 as bit)
                  
	IF @sum_pay IS NULL SET @sum_pay=0
  
	SELECT @res=SUM(p.SALDO)
	FROM dbo.OCC_SUPPLIERS as os
	JOIN dbo.View_PAYM AS p 
		ON os.occ=p.occ and os.fin_id=p.fin_id
	JOIN dbo.CONSMODES_LIST AS cl
		ON p.occ=cl.occ AND p.service_id=cl.service_id AND os.occ_sup=cl.occ_serv
	JOIN dbo.View_SERVICES AS s
		ON p.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
	WHERE os.occ=@occ1
		 AND os.fin_id=@fin_id
		 AND os.sup_id=@sup_id
		 AND (p.account_one=cast(1 as bit))

	IF @res IS NULL SET @res=0   
	SET @res=@res-@sum_pay
 
RETURN @res
END
go

