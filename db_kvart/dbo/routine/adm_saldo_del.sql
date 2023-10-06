CREATE   PROCEDURE [dbo].[adm_saldo_del]
(
	@tip_id	  SMALLINT = NULL
   ,@build_id INT	   = NULL
   ,@sup_id	  INT	   = NULL
)
AS
	/*
	
	Удаление сальдо по дому или типу фонда
	
	дата последней модификации:  10.05.16
	автор изменений: Пузанов М.А.
				
	EXEC adm_saldo_del @tip_id=null, @build_id=4568, @sup_id=NULL
			
	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @tip_id IS NULL
		AND @build_id IS NULL
		RETURN

	IF @sup_id IS NULL
		SET @sup_id = 0

	-- Таблица с лицевыми для обнуления сальдо
	DECLARE @T1 TABLE
		(
			occ	   INT PRIMARY KEY
		   ,fin_id SMALLINT
		)

	INSERT INTO @T1
	(occ
	,fin_id)
		SELECT
			occ
		   ,voa.fin_id
		FROM dbo.View_OCC_ALL voa
		JOIN dbo.OCCUPATION_TYPES OT
			ON voa.tip_id = OT.Id
			AND voa.fin_id = OT.fin_id
		WHERE 
			voa.bldn_id = COALESCE(@build_id, voa.bldn_id)
			AND voa.tip_id = COALESCE(@tip_id, voa.tip_id)
			AND voa.status_id <> 'закр'

	DECLARE @row_update INT = 0

	BEGIN TRAN

		UPDATE p
		SET SALDO = 0
		FROM dbo.PAYM_LIST AS p
		JOIN @T1 AS t
			ON p.occ = t.occ
			AND p.fin_id = t.fin_id
		WHERE p.sup_id = @sup_id;

		UPDATE o 
		SET saldo_edit = 1		-- ручное изменение сальдо
		FROM dbo.Occupations AS o
		JOIN @T1 t
			ON o.occ = t.occ;
		SET @row_update = @@rowcount


	COMMIT TRAN

		PRINT 'update = ' + STR(@row_update)

		IF @tip_id > 0
			AND @build_id IS NULL
			RETURN

		-- Делаем перерасчёт если только меняли сальдо по дому
		DECLARE @Occ	  INT
			   ,@Fin_Id	  SMALLINT
			   ,@comments VARCHAR(50) = 'Обнулили из админа'

		IF @sup_id > 0
		BEGIN
			SELECT
				@comments = @comments + ' по ' + sa.name
			FROM Suppliers_all sa
			WHERE sa.Id = @sup_id
		END


		DECLARE cursor_name CURSOR FOR
			SELECT
				occ
			   ,fin_id
			FROM @T1

		OPEN cursor_name;

		FETCH NEXT FROM cursor_name INTO @Occ, @Fin_Id;

		WHILE @@fetch_status = 0
		BEGIN

			-- сохраняем в историю изменений
			EXEC k_write_log @Occ
							,'слдо'
							,@comments

			EXEC k_raschet_1 @occ1 = @Occ
							,@fin_id1 = @Fin_Id

			FETCH NEXT FROM cursor_name INTO @Occ, @Fin_Id;

		END

		CLOSE cursor_name;
		DEALLOCATE cursor_name;
go

