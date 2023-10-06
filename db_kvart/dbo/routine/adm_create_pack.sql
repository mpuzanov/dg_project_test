CREATE   PROCEDURE [dbo].[adm_create_pack]
(
	@date1			  DATETIME = NULL
   ,@date2			  DATETIME = NULL
   ,@bank_id1		  INT	   = NULL -- Код организации (Банк, УК)
   ,@debug			  BIT	   = 0
   ,@tip_id			  SMALLINT = NULL -- Тип фонда
   ,@kolpacks		  INT	   = 0 OUTPUT -- количество сформированных пачек
   ,@sup_id			  INT	   = NULL
   ,@is_test		  BIT	   = 0 -- 1 проверяем сколько пачек будет сформировано
   ,@bank_ext		  VARCHAR(10)  = NULL  -- тип платежа
   ,@filedbf_id1	  INT	   = NULL
   ,@is_closeOpenPack BIT	   = NULL
   ,@kolPacksClose	  INT	   = 0 OUTPUT -- количество закрыто пачек
)
AS
	/*
	
DECLARE @kolpacks	INT=0 ,@kolPacksClose INT=0
exec adm_create_pack @date1='20170526',@date2='20170526',@bank_id1=null,@debug=1,@tip_id=null,@kolpacks=@kolpacks OUT,
@sup_id=NULL,@is_test=1,@bank_ext=NULL
SELECT @kolpacks AS kolpacks, @kolPacksClose as kolPacksClose

DECLARE @kolpacks	INT=0 ,@kolPacksClose INT=0
EXEC adm_create_pack   @date1='20190704', @date2='20190704', @bank_id1=NULL, @debug=1, 
@tip_id=NULL, @kolpacks=@kolpacks OUT, @sup_id=NULL, @is_test=0, @bank_ext=NULL, 
@filedbf_id1=NULL, @is_closeOpenPack=1, @kolPacksClose=@kolPacksClose OUT
SELECT @kolpacks AS kolpacks, @kolPacksClose as kolPacksClose
	
	Формирование пачек по электронным платежам
	
	автор:  Пузанов М.А.
	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON


	DECLARE @fin_current	 SMALLINT
		   ,@Pdate			 DATE
		   ,@KolOcc			 INT
		   ,@occ1			 INT
		   ,@SumOplPack		 DECIMAL(15, 2)
		   ,@SumOplPay		 DECIMAL(15, 2)
		   ,@service_id		 VARCHAR(10)
		   ,@commission_pack DECIMAL(9, 2)
		   ,@id_pack		 INT -- код пачки
		   ,@id_pay			 INT -- код введенного платежа
		   ,@id_bankdbf		 INT -- код электронного платежа
		   ,@id_bank		 INT -- код вида платежа по банку банка
		   ,@Kol			 INT -- для сравнения (п.4)
		   ,@Sum			 DECIMAL(15, 2) -- для сравнения (п.4)
		   ,@user_id1		 SMALLINT

	SELECT
		@user_id1 = id
	FROM dbo.USERS 
	WHERE login = system_user

	IF @bank_id1 = 0
		SET @bank_id1 = NULL

	SELECT
		@kolpacks = 0
	   ,@kolPacksClose = 0

	IF @date1 IS NULL
		AND @date2 IS NULL
		AND @filedbf_id1 IS NULL
		RETURN

	IF @date1 IS NULL
		AND @date2 IS NULL
		AND @filedbf_id1 IS NOT NULL
		SELECT
			@date1 = MIN(bd.Pdate)
		   ,@date2 = MAX(bd.Pdate)
		FROM dbo.Bank_Dbf bd
		WHERE bd.filedbf_id = @filedbf_id1
		GROUP BY bd.filedbf_id;

	IF @debug = 1
		PRINT CONCAT(CONVERT(VARCHAR(12), @date1, 104), ' ',CONVERT(VARCHAR(12), @date2, 104) )

	--SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
	--SELECT @DateClosePaym=PaymClosedData FROM dbo.global_values WHERE fin_id=@fin_current-1

	IF @date1 < '20021219'
		SET @date1 = '20021219'

	BEGIN TRY

		-- все платежи из которых формируем пачки 
		DECLARE @t_bank_dbf TABLE
			(
				id			INT			   PRIMARY KEY
			   ,Pdate		DATE
			   ,bank_id		VARCHAR(10)
			   ,tip_id		SMALLINT
			   ,occ			INT
			   ,Sum_Opl		DECIMAL(15, 2) DEFAULT 0
			   ,service_id  VARCHAR(10)
			   ,sup_id		INT			   DEFAULT 0 NOT NULL
			   ,fin_id		SMALLINT
			   ,dog_int		INT
			   ,filedbf_id  INT
			   ,commission  DECIMAL(9, 2)  DEFAULT 0
			   ,occ_sup		INT			   DEFAULT NULL
			   ,FileNameDbf VARCHAR(100)   DEFAULT NULL
			   ,bank_int	INT			   DEFAULT NULL
			)

		-- в этой таблице формируем пачки
		DECLARE @t TABLE
			(
				Pdate		DATE
			   ,bank_id		VARCHAR(10)
			   ,tip_id		SMALLINT
			   ,sup_id		INT
			   ,KolOcc		INT
			   ,SumOpl		DECIMAL(15, 2)
			   ,fin_id		SMALLINT
			   ,commission  DECIMAL(9, 2)
			   ,FileNameDbf VARCHAR(1000) DEFAULT NULL -- здесь перечисляются файлы через запятую
			   ,bank_int	INT			 DEFAULT NULL
			);

		--*** debug *********************************
		IF @debug = 1
		BEGIN
			SELECT DISTINCT
				pc.ext
			   ,pc.bank AS bank_int
			FROM dbo.View_paycoll_orgs AS pc
			WHERE 
				(@bank_id1 IS NULL OR pc.bank = @bank_id1);

			WITH PAYYCOLL1
			AS
			(SELECT DISTINCT
					pc.ext
				   ,pc.bank AS bank_int
				FROM dbo.View_paycoll_orgs AS pc
				WHERE 
					(@bank_id1 IS NULL OR pc.bank = @bank_id1)
				)

			SELECT
				bd.id
			   ,bd.Pdate
			   ,bd.bank_id
			   ,o.tip_id
			   ,bd.occ
			   ,bd.Sum_Opl
			   ,bd.service_id
			   ,bd.sup_id
			   ,CASE
					WHEN (ot.ras_paym_fin_new = 1) AND
					(ot.PaymClosed = 1) THEN ot.fin_id + 1
					ELSE ot.fin_id
				END
			   ,bd.dog_int
			   ,bd.filedbf_id
			   ,bd.commission
			   ,CASE
					WHEN bd.sch_lic > 999999999 THEN 0
					ELSE bd.sch_lic
				END
			   ,BTS.FileNameDbf
			   ,pc.bank_int
			FROM dbo.Bank_Dbf AS bd
				JOIN dbo.Occupations AS o
					ON bd.occ = o.occ
				JOIN PAYYCOLL1 AS pc
					ON pc.ext = bd.bank_id
				JOIN dbo.VOcc_types_access AS ot -- для ограничения доступа
					ON o.tip_id = ot.id
				JOIN dbo.Bank_tbl_spisok AS BTS
					ON bd.filedbf_id = BTS.filedbf_id -- для того чтобы лишних платежей не было
				JOIN dbo.Flats as f ON 
					o.flat_id=f.id
				JOIN dbo.Buildings as b ON 
					f.bldn_id=b.id
			WHERE bd.pack_id IS NULL
				AND bd.Pdate BETWEEN @date1 AND @date2
				AND bd.occ IS NOT NULL
				AND ot.id > 0 -- для типа фонда "Неизвестно" не формируем
				AND (ot.PaymClosed = CAST(0 AS BIT) -- только где Платёжный период открыт
					OR ot.ras_paym_fin_new = CAST(1 AS BIT))
				AND o.status_id <> 'закр' -- не формировать пачки по закрытым лицевым
				AND (o.tip_id = @tip_id	OR @tip_id IS NULL)
				AND (bd.sup_id = @sup_id OR @sup_id IS NULL)
				AND BTS.block_import = CAST(0 AS BIT)
				AND (bd.bank_id = @bank_ext	OR @bank_ext IS NULL)
				AND (bd.filedbf_id = @filedbf_id1 OR @filedbf_id1 IS NULL)
				AND b.blocked_house = CAST(0 AS BIT) -- дом не блокирован для оплаты 02.03.2022;
		END;
		--*** debug *********************************

		WITH PAYYCOLL
		AS
		(SELECT DISTINCT
				pc.ext
			   ,pc.bank AS bank_int
			FROM dbo.View_PAYCOLL_ORGS AS pc
			WHERE (pc.bank = @bank_id1
			OR @bank_id1 IS NULL))

		-- заносим платежи
		INSERT INTO @t_bank_dbf
		(id
		,Pdate
		,bank_id
		,tip_id
		,occ
		,Sum_Opl
		,service_id
		,sup_id
		,fin_id
		,dog_int
		,filedbf_id
		,commission
		,occ_sup
		,FileNameDbf
		,bank_int)
			SELECT
				bd.id
			   ,bd.Pdate
			   ,bd.bank_id
			   ,o.tip_id
			   ,bd.occ
			   ,bd.Sum_Opl
			   ,bd.service_id
			   ,bd.sup_id
			   ,CASE
					WHEN (ot.ras_paym_fin_new = 1) AND
					(ot.PaymClosed = 1) THEN ot.fin_id + 1
					ELSE ot.fin_id
				END
			   ,bd.dog_int
			   ,bd.filedbf_id
			   ,COALESCE(bd.commission, 0)
			   ,CASE
					WHEN bd.sch_lic > 999999999 THEN 0
					ELSE bd.sch_lic
				END
			   ,BTS.FileNameDbf
			   ,pc.bank_int
			FROM dbo.Bank_Dbf AS bd
				JOIN dbo.Occupations AS o ON 
					bd.occ = o.occ
				JOIN PAYYCOLL AS pc ON 
					pc.ext = bd.bank_id
				JOIN dbo.VOcc_types_access AS ot ON -- для ограничения доступа
					o.tip_id = ot.id
				JOIN dbo.Bank_tbl_spisok AS BTS	ON 
					bd.filedbf_id = BTS.filedbf_id -- для того чтобы лишних платежей не было
				JOIN dbo.Flats as f ON 
					o.flat_id=f.id
				JOIN dbo.Buildings as b ON 
					f.bldn_id=b.id
			WHERE bd.pack_id IS NULL
				AND bd.Pdate BETWEEN @date1 AND @date2
				AND bd.occ IS NOT NULL
				AND ot.id > 0 -- для типа фонда "Неизвестно" не формируем
				AND (ot.PaymClosed = CAST(0 AS BIT) -- только где Платёжный период открыт
					OR ot.ras_paym_fin_new = CAST(1 AS BIT))
				AND o.status_id <> 'закр' -- не формировать пачки по закрытым лицевым
				AND (@tip_id IS NULL OR o.tip_id = @tip_id)
				AND (@sup_id IS NULL OR bd.sup_id = @sup_id)
				AND BTS.block_import = CAST(0 AS BIT)
				AND (bd.bank_id = @bank_ext OR @bank_ext IS NULL)
				AND (bd.filedbf_id = @filedbf_id1 OR @filedbf_id1 IS NULL)
				AND b.blocked_house=CAST(0 AS BIT) -- дом не блокирован для оплаты 02.03.2022

		IF @debug = 1
			SELECT
				'@t_bank_dbf' as tbl, *
			FROM @t_bank_dbf
			ORDER BY occ


		-- группируем по пачкам
		INSERT INTO @t
		(Pdate
		,bank_id
		,tip_id
		,sup_id
		,fin_id
		,KolOcc
		,SumOpl
		,commission
		,FileNameDbf
		,bank_int)
			SELECT
				t.Pdate
			   ,t.bank_id
			   ,t.tip_id
			   ,COALESCE(t.sup_id, 0)
			   ,t.fin_id
			   ,COUNT(t.occ) AS Kol_occ
			   ,SUM(t.sum_opl) AS sum_opl
			   ,SUM(t.commission) AS commission
			   ,LTRIM(STUFF((SELECT
						', ' + FileNameDbf
					FROM @t_bank_dbf AS ap
					WHERE ap.Pdate = t.Pdate
						AND ap.bank_id = t.bank_id
						AND ap.tip_id = t.tip_id
						AND ap.sup_id = t.sup_id
						AND ap.fin_id = t.fin_id
					GROUP BY FileNameDbf
					FOR XML PATH (''))
				,1, 1, '')) AS FileNameDbf
			   ,MIN(t.bank_int)
			FROM @t_bank_dbf t
			GROUP BY Pdate
					,bank_id
					,tip_id
					,sup_id
					,fin_id

		SELECT
			t.Pdate
		   ,t.bank_id
		   ,CONCAT(b.bank_name , ' (' , b.tip_paym , ')') AS bank_name
		   ,t.tip_id
		   ,ot.name AS tip_name
		   ,t.sup_id
		   ,sa.name AS sup_name
		   ,KolOcc
		   ,t.SumOpl
		   ,t.fin_id
		   ,t.commission
		   ,t.FileNameDbf
		   ,t.bank_int
		FROM @t t
		JOIN dbo.View_paycoll_orgs b 
			ON t.bank_id = b.ext
			AND t.fin_id = b.fin_id
		JOIN dbo.Suppliers_all sa 
			ON t.sup_id = sa.id
		JOIN dbo.VOcc_types AS ot 
			ON t.tip_id = ot.id
		SELECT
			@kolpacks = @@rowcount
		IF @is_test = 1
			RETURN

		DECLARE @PackClose INT = 0
			,@pack_uid UNIQUEIDENTIFIER

		SELECT
			@kolpacks = 0

		DECLARE curs_1 CURSOR LOCAL FOR
			SELECT
				Pdate
			   ,bank_id
			   ,tip_id
			   ,fin_id
			   ,KolOcc
			   ,SumOpl
			   ,commission
			   ,sup_id
			FROM @t
		OPEN curs_1
		FETCH NEXT FROM curs_1 INTO @Pdate, @bank_ext, @tip_id, @fin_current, @KolOcc, @SumOplPack, @commission_pack, @sup_id

		WHILE (@@fetch_status = 0)
		BEGIN
			BEGIN TRAN

			--1. Формируем пачку в PAYDOC_PACKS
			SELECT
				@id_bank = id				
			FROM dbo.Paycoll_orgs
			WHERE fin_id = @fin_current
			AND ext = @bank_ext

			IF @id_bank IS NULL
			BEGIN
				SELECT TOP 1
					@id_bank = id
				FROM dbo.Paycoll_orgs
				WHERE ext = @bank_ext
				ORDER BY fin_id DESC

				IF @id_bank IS NULL
				BEGIN
					RAISERROR ('Не найден вид платежа у кодом %s ', 16, 1, @bank_ext)
				END

			END

			SELECT @pack_uid=dbo.fn_newid()
			IF @debug=1
				PRINT CONCAT('@pack_uid=', @pack_uid)

			INSERT INTO dbo.Paydoc_packs
			(fin_id
			,source_id
			,day
			,docsnum
			,total
			,checked
			,forwarded
			,user_edit
			,date_edit
			,tip_id
			,commission
			,sup_id
			,pack_uid)
			VALUES (@fin_current
				   ,@id_bank
				   ,@Pdate
				   ,@KolOcc
				   ,@SumOplPack
				   ,0
				   ,0
				   ,@user_id1
				   ,current_timestamp
				   ,@tip_id
				   ,COALESCE(@commission_pack, 0)
				   ,COALESCE(@sup_id, 0)
				   ,@pack_uid)

			SELECT
				@id_pack = SCOPE_IDENTITY() -- код новой пачки

			--2. Формируем платежи по пачке в PAYINGS
			IF @debug = 1
				SELECT
					'Формируем платежи по пачке в PAYINGS'
				   ,@id_pack AS id_pack
				   ,occ
				   ,service_id
				   ,Sum_Opl
				   ,sup_id
				   ,fin_id
				FROM @t_bank_dbf
				WHERE Pdate = @Pdate
				AND bank_id = @bank_ext
				AND tip_id = @tip_id

			INSERT INTO dbo.Payings
			(pack_id
			,occ
			,fin_id
			,service_id
			,value
			,checked
			,forwarded
			,scan
			,sup_id
			,dog_int
			,filedbf_id
			,commission
			,occ_sup
			,PaymAccount_peny)
				SELECT
					@id_pack
				   ,occ
				   ,fin_id
				   ,service_id
				   ,Sum_Opl
				   ,0
				   ,0
				   ,2
				   ,sup_id
				   ,dog_int
				   ,filedbf_id
				   ,COALESCE(commission, 0)
				   ,occ_sup
				   ,0 AS paymaccount_peny
				FROM @t_bank_dbf
				WHERE 
					Pdate = @Pdate
					AND bank_id = @bank_ext
					AND tip_id = @tip_id
					AND sup_id = COALESCE(@sup_id, 0) --AND ((sup_id = @sup_id) OR (@sup_id is null and sup_id=0))

			-- 3. Изменяем номер пачки в таблице BANK_DBF
			UPDATE bd
			SET pack_id = @id_pack
			FROM dbo.BANK_DBF AS bd
			JOIN @t_bank_dbf AS t
				ON bd.id = t.id
			WHERE 
				t.Pdate = @Pdate
				AND t.bank_id = @bank_ext
				AND t.tip_id = @tip_id
				AND t.sup_id = COALESCE(@sup_id, 0)

			--4. Сравниваем итоги по пачке и платежи в пачке 
			SELECT
				@Kol = COUNT(occ)
			   ,@Sum = SUM(value)
			FROM dbo.PAYINGS
			WHERE pack_id = @id_pack

			IF (@Kol = @KolOcc)
				AND (@Sum = @SumOplPack)
			BEGIN
				UPDATE dbo.PAYINGS
				SET checked = 1
				   ,fin_id  = CASE WHEN fin_id IS NULL THEN @fin_current ELSE fin_id END
				WHERE pack_id = @id_pack

				UPDATE dbo.Paydoc_packs
				SET checked = 1
				WHERE id = @id_pack

				SET @kolpacks = @kolpacks + 1

				IF @debug = 1
					PRINT CONCAT('@id_pack:', @id_pack, '  @KolOcc:', @KolOcc, '  @SumOplPack:', @SumOplPack, ' @kolpacks=', @kolpacks)
				
				IF @is_closeOpenPack = 1
				BEGIN
					IF @debug = 1
						PRINT 'Закрываем пачку ' + STR(@id_pack)

					SELECT
						@PackClose = 0

					EXEC adm_CloseDay @closedate1 = NULL
									 ,@ras1 = 0 -- признак расчета
									 ,@ras_peny = 0 -- признак расчета пени(для расчёта оплат пени)
									 ,@debug = @debug
									 ,@tip_id = NULL -- Тип фонда
									 ,@pack_id = @id_pack -- если нужно закрыть одну пачку  
									 ,@sup_id = NULL -- закрыть только по поставщику
									 ,@bank_id = NULL
									 ,@kolPacksClose = @PackClose OUT
					IF @debug = 1
						PRINT 'Результат закрытия: ' + STR(@PackClose)

					SELECT
						@kolPacksClose = @kolPacksClose + @PackClose
				END

				COMMIT TRAN
			END
			ELSE
			BEGIN
				ROLLBACK TRAN
			END

			FETCH NEXT FROM curs_1 INTO @Pdate, @bank_ext, @tip_id, @fin_current, @KolOcc, @SumOplPack, @commission_pack, @sup_id
		END

		CLOSE curs_1
		DEALLOCATE curs_1

		IF @debug = 1
			PRINT 'Закрыто пачек:' + STR(@kolPacksClose)

	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

