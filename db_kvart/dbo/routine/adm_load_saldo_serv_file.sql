-- =============================================
-- Author:		Пузанов
-- Create date: 28.08.2012
-- Description:	Загрузка данных сальдо по услугам   используется в АРМ Экспорт
-- =============================================
CREATE       PROCEDURE [dbo].[adm_load_saldo_serv_file]
	@tip_id			SMALLINT
	,@FileIn		NVARCHAR(MAX)  
	,@isSumValue	BIT	= 0 -- суммировать новое сальдо с текщим
	,@SumSaldoOk	DECIMAL(15,2) = 0 OUTPUT 
	,@CountOk		INT = 0 OUTPUT 
	,@debug			BIT = 0
	,@isSverka		BIT = 0
AS
/*
DECLARE @RC int
DECLARE @tip_id smallint = 1
DECLARE @FileIn nvarchar(max)
DECLARE @isSumValue bit
DECLARE @SumSaldoOk decimal(15,2)
DECLARE @CountOk int
DECLARE @debug BIT = 0

SELECT @FileIn='
{"data":[{"occ":"166149","service_id":"пзар","saldo":"3.68"},{"occ":"166149","service_id":"Пзиз","saldo":"0.92"}]}
'
EXECUTE @RC = [dbo].[adm_load_saldo_serv_file] 
   @tip_id
  ,@FileIn
  ,@isSumValue
  ,@SumSaldoOk OUTPUT
  ,@CountOk OUTPUT
  ,@debug

SELECT @SumSaldoOk, @CountOk

*/
BEGIN
	SET NOCOUNT ON;

	SELECT @SumSaldoOk=0, @CountOk=0

	DECLARE @occ1 INT, 
		@sup_id int, 
		@service_id VARCHAR(10), 
		@saldo	DECIMAL(9, 2), 
		@fin_id SMALLINT = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	DECLARE @File_TMP TABLE(
		occ int, 
		service_id VARCHAR(10), 
		saldo	DECIMAL(9, 2) Default 0, 
		Result VARCHAR(100) Default NULL
	)
	
	-- переносим данные из JSON
	INSERT @File_TMP
	(occ
	,service_id
	,saldo)
	SELECT
		occ
	   ,service_id
	   ,saldo
	FROM OPENJSON(@FileIn, '$.data')
	WITH (
		occ INT '$."occ"'
		,service_id VARCHAR(10) '$."service_id"'
		,saldo DECIMAL(9, 2) '$."saldo"'
	) AS t

	DECLARE @File_out TABLE(
		occ int, 
		occ_in int,
		service_id VARCHAR(10), 
		sup_id int Default 0,
		saldo	DECIMAL(9, 2) Default 0, 
		result VARCHAR(100) Default NULL,
		PRIMARY KEY (occ, service_id, sup_id)
	)

	-- по одинаковым услугам на лицевом суммируем сальдо
	INSERT INTO @File_out(occ,occ_in,service_id,saldo)
	SELECT occ,occ,service_id,sum(saldo)
	FROM @File_TMP
	GROUP BY occ,service_id

	-- Проверяем
	-- наличие лицевого счёта
	UPDATE t
	SET Result='лицевой счёт не найден'
	FROM @File_out as t
	WHERE not Exists(select 1 FROM dbo.Occupations as o WHERE o.occ=t.occ)
	AND not Exists(select 1 FROM dbo.Occ_Suppliers as os WHERE os.occ_sup=t.Occ)
	
	UPDATE t
	SET Result='услуга не найдена в базе'
	FROM @File_out as t
	WHERE not Exists(select 1 FROM dbo.Services as s WHERE s.id=t.service_id)

	UPDATE t
	SET sup_id=os.sup_id,
		occ=os.occ
	FROM @File_out as t
	JOIN dbo.Occ_suppliers as os 
		ON t.occ_in=os.occ_sup and os.fin_id=@fin_id
	where t.result is null

	UPDATE t
	SET Result='лицевой счёт закрыт'
	FROM @File_out as t
	JOIN dbo.Occupations as o 
		ON o.occ=t.occ
	where o.status_id='закр'

	if @debug=1
		SELECT TOP(100) * from @File_out

	DECLARE @Log TABLE
	(
		Result VARCHAR(100) Default NULL,
		occ int, 
		service_id VARCHAR(10), 
		saldo	DECIMAL(9, 2) Default 0
	);

	-- обновляем сальдо
	MERGE dbo.Paym_list AS pl USING @File_out AS t
	ON pl.occ = t.occ
		AND pl.service_id = t.service_id
		--AND pl.sup_id = t.sup_id
	WHEN MATCHED AND t.result is NULL 
		AND pl.saldo<> CASE
                           WHEN @isSumValue = 1 THEN pl.saldo + t.saldo
                           ELSE t.saldo
            END
	THEN UPDATE
		SET pl.saldo	= CASE
                              WHEN @isSumValue = 1 THEN pl.saldo + t.saldo
                              ELSE t.saldo
            END
	WHEN NOT MATCHED AND t.result is NULL
	THEN INSERT
		(fin_id
		,occ
		,service_id
		,sup_id
		,saldo)
	VALUES (@fin_id,
			t.occ
			,t.service_id
			,t.sup_id
			,t.saldo)
	OUTPUT 
	$action AS Result
	,INSERTED.occ,INSERTED.service_id,INSERTED.saldo
	--,DELETED.occ,DELETED.service_id,DELETED.saldo
	INTO @Log;

	UPDATE o 
	SET saldo_edit = 1
	From dbo.Occupations as o 
	JOIN @File_out as t ON o.occ=t.occ
	WHERE t.result is NULL

	SELECT @SumSaldoOk=SUM(COALESCE(saldo,0)), @CountOk=COUNT(*)
	FROM @File_out 
	WHERE result is null

	-- добавим режимы на лицевые счета по умолчанию (а то после перерасчёта пропадают записи из Paym_list)
	INSERT INTO dbo.Consmodes_list
	(occ,service_id,sup_id,mode_id,source_id,fin_id)
	SELECT pl.occ,pl.service_id,pl.sup_id
		,(s.service_no*1000) as mode_id
		,(s.service_no*1000) as source_id
		,pl.fin_id
	FROM dbo.Paym_list as pl 
		join @File_out AS t ON pl.occ = t.occ AND pl.service_id = t.service_id
		join dbo.Services as s ON pl.service_id=s.id
	WHERE not exists(SELECT 1 FROM dbo.Consmodes_list as cl 
					WHERE cl.occ=pl.occ and cl.service_id=pl.service_id and cl.sup_id=pl.sup_id)


	if @isSverka=1
		Update f set result=t.result
		FROM @File_out f 
		JOIN @log as t ON f.occ=t.occ and f.service_id=t.service_id

	-- выдаём только ошибки
	SELECT 'table_error' as tabl, occ_in as occ, service_id, result
	FROM @File_out where result is not null

END;
go

