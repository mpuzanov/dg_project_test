CREATE   PROCEDURE [dbo].[k_Find_payings]
(
	@date1	   DATETIME		 = NULL
   ,@summa1	   DECIMAL(9, 2) = NULL
   ,@tip_id	   SMALLINT		 = NULL
   ,@occ	   INT			 = NULL
   ,@pack_id   INT			 = NULL
   ,@paying_id INT			 = NULL
   ,@filename  VARCHAR(50)	 = NULL
   ,@paying_uid VARCHAR(36) = NULL
   ,@pack_uid  VARCHAR(36)  = NULL
)
AS
	/*
		--  Поиск платежей
		используется в АРМ "ПЛАТЕЖИ"  // Список пачек-Поиск платежей
			
	exec k_Find_payings @date1='20170316',@summa1=NULL,@tip_id=NULL,@occ=NULL,@pack_id=NULL
	exec k_Find_payings @date1=NULL,@summa1=NULL,@tip_id=NULL,@occ=NULL,@pack_id=89017,@paying_id=NULL,@filename=''
	exec k_Find_payings @date1=NULL,@summa1=NULL,@tip_id=NULL,@occ=NULL,@pack_id=NULL,@filename='0316.rpp'
	exec k_Find_payings @date1=NULL,@summa1=NULL,@tip_id=NULL,@occ=NULL,@pack_id=NULL,@filename='417_08082018_545098.txt'
	
	*/

	SET NOCOUNT ON

	IF @occ = 0
		SET @occ = NULL
	IF @filename = ''
		SET @filename = NULL

	IF @date1 IS NULL
		AND @summa1 IS NULL
		AND @tip_id IS NULL
		AND @occ IS NULL
		AND @pack_id IS NULL
		AND @paying_id IS NULL
		AND @filename IS NULL
		SET @summa1 = 0

	SELECT TOP 1000
		p.id
	   ,p.pack_id
	   ,p.occ
	   ,o.address AS adres
	   ,p.value AS summa
	   ,p.paymaccount_peny
	   ,p.commission
	   ,cp.StrFinPeriod AS fin_id
	   ,t_source.source AS source
	   ,u.Initials AS user_edit
	   ,p2.forwarded
	   ,p2.checked
	   ,P.sup_id
	   ,o.tip_name
	   ,p2.day
	   ,p2.date_edit
	   ,bts.FILENAMEDBF AS filename
	   ,ROW_NUMBER() OVER (PARTITION BY p.occ, p.value ORDER BY p.pack_id) AS DoubleOccSum
	FROM dbo.Payings AS p 
	JOIN dbo.Paydoc_packs AS p2 
		ON p.pack_id = p2.id
	JOIN dbo.VOcc AS o 
		ON p.occ = o.occ
	LEFT JOIN dbo.Users u
		ON u.id = p2.user_edit
	LEFT JOIN dbo.Calendar_period cp 
		ON cp.fin_id = p2.fin_id
	LEFT JOIN dbo.Bank_tbl_spisok bts 
		ON p.filedbf_id = bts.filedbf_id
	OUTER APPLY (SELECT TOP 1
			concat(b.short_name , '(' , RTRIM(pt.name) , ')') AS source
		FROM dbo.Paycoll_orgs AS po 
		JOIN dbo.Bank AS b ON 
			po.BANK = b.id
		JOIN dbo.PAYING_TYPES AS pt ON 
			po.vid_paym = pt.id
		WHERE po.id = p2.source_id) AS t_source

	WHERE (p2.day = @date1
		OR @date1 IS NULL)
		AND (p.value = @summa1
		OR @summa1 IS NULL)
		AND (o.tip_id = @tip_id
		OR @tip_id IS NULL)
		AND (p.occ = @occ
		OR @occ IS NULL)
		AND (p.pack_id = @pack_id
		OR @pack_id IS NULL)
		AND (p.id = @paying_id
		OR @paying_id IS NULL)
		AND (bts.FILENAMEDBF = @filename
		OR @filename IS NULL)
		AND (p.paying_uid =CAST(@paying_uid AS UNIQUEIDENTIFIER)
		OR @paying_uid is NULL)
		AND (p2.pack_uid = CAST(@pack_uid AS UNIQUEIDENTIFIER)
		OR @pack_uid is NULL)
	ORDER BY p2.fin_id DESC, p2.day DESC, p.occ
go

