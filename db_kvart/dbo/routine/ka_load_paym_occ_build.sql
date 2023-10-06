-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[ka_load_paym_occ_build]
(
	@FileJson    NVARCHAR(MAX)
   ,@count_added INT		 = 0 OUTPUT -- кол-во добавленных записей
   ,@debug		 BIT			 = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	-- проверяем файл 
	IF @FileJson IS NULL
		OR ISJSON(@FileJson) = 0
	BEGIN
		RAISERROR('Входной файл не в JSON формате',16,10)				
		RETURN -1
	END

	DECLARE @File_TMP TABLE
	(
		fin_id			SMALLINT		DEFAULT 0
		,occ			INT
		,service_id		VARCHAR(10)
		,kol			DECIMAL(15, 6)	DEFAULT 0
		,tarif			DECIMAL(12, 4)	DEFAULT 0
		,value			DECIMAL(9, 2)	DEFAULT 0
		,unit_id		VARCHAR(10)		DEFAULT NULL
		,comments		VARCHAR(100)	DEFAULT NULL
		,PRIMARY KEY (fin_id, occ, service_id)
	)
	-- переносим данные из JSON
	INSERT @File_TMP
	(occ
	,service_id
	,kol
	,value
	,comments)
		SELECT
			occ
			,service_id
			,kol
			,coalesce(value,0)
			,doc
		FROM OPENJSON(@FileJson, '$.data')
		WITH (
		occ INT '$.occ'
		,service_id VARCHAR(10) '$."service_id"'
		,kol DECIMAL(15, 6) '$."kol"'
		,value DECIMAL(9, 2) '$."sumadd"'
		,doc VARCHAR(100) '$."doc"'
		) AS t2

	IF @debug = 1 SELECT * FROM @File_TMP

	DECLARE @fin_id1 SMALLINT
			,@sup_id INT = 0
			,@occ1 INT
			,@service_id1 VARCHAR(10)

	SELECT TOP(1) 
		@occ1 = occ
		,@service_id1 = service_id
	FROM @File_TMP

	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
	UPDATE @File_TMP SET fin_id=@fin_id1

	-- определить ед.изм. по услуге
	--DECLARE @unit_id VARCHAR(10)
	-- определить тариф по услуге
	--DECLARE @tarif DECIMAL(12, 4) = 0
	--SELECT @tarif = dbo.Fun_GetCounterTarfServ(@fin_id1, @occ1, @service_id1, @unit_id)

	UPDATE f
		SET tarif= p.tarif 
		,unit_id = p.unit_id
	From @File_TMP as f
	JOIN dbo.View_paym as p ON f.occ=p.occ AND f.service_id=p.service_id and f.fin_id=p.fin_id
	WHERE f.tarif=0

	-- рассчитать сумму если её нет
	UPDATE @File_TMP SET value=kol*tarif WHERE value=0

	
BEGIN TRAN

		DELETE pcb
			FROM dbo.PAYM_OCC_BUILD AS pcb
			JOIN @File_TMP AS t
				ON pcb.occ = t.occ AND pcb.service_id = t.service_id and pcb.fin_id=t.fin_id
			

		INSERT
		INTO dbo.PAYM_OCC_BUILD 
		(	fin_id
			,occ
			,service_id
			,kol
			,tarif
			,value
			,comments
			,unit_id
			,procedura
			,kol_add
			)
				SELECT
					t.fin_id
					,t.occ
					,t.service_id
					,t.kol
					,t.tarif
					,t.value
					,t.comments
					,t.unit_id
					,procedura = 'ka_load_paym_occ_build'
					,0 --kol_add
				FROM @File_TMP AS t
				WHERE COALESCE(t.kol, 0) <> 0 OR (COALESCE(value, 0)<>0)
		SELECT
			@count_added = @@rowcount

	COMMIT TRAN


END
go

