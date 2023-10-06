CREATE   PROCEDURE [dbo].[k_del_sup_dog]
(
	@tip_id		SMALLINT	= NULL
	,@build_id	SMALLINT	= NULL
	,@dog_int	INT			= NULL
	,@kol_del	INT			= 0 OUTPUT
	,@sup_id	INT			= NULL
)
AS
	/*

  Процедура удаления лицевого счета поставщика по типу фонда и договору
  
21/09/2012  

*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE	@fin_id		SMALLINT
			,@occ		INT
			,@occ_sup	INT
			,@msg		VARCHAR(50)

	IF @tip_id IS NULL
		AND @build_id IS NULL
		RETURN

	IF @sup_id IS NULL
		AND @dog_int IS NOT NULL
		SELECT
			@sup_id = sup_id
		FROM dbo.DOG_SUP AS DS
		WHERE id = @dog_int

	IF @sup_id IS NULL
		RETURN

	DECLARE @t_occ_sup TABLE
		(
			occ			INT
			,occ_sup	INT
			,fin_id		SMALLINT
		)
	INSERT
	INTO @t_occ_sup
	(	occ
		,occ_sup
		,fin_id)
		SELECT
			os.occ
			,occ_sup
			,os.fin_id
		FROM dbo.OCC_SUPPLIERS AS os 
		JOIN dbo.OCCUPATIONS AS O 
			ON os.occ = O.occ AND os.fin_id = O.fin_id					
		JOIN dbo.FLATS AS f 
			ON O.flat_id = f.id
		WHERE os.dog_int = COALESCE(@dog_int, os.dog_int)
		AND os.sup_id = COALESCE(@sup_id, os.sup_id)
		AND O.tip_id = COALESCE(@tip_id, O.tip_id)
		AND f.bldn_id = COALESCE(@build_id, f.bldn_id)

	SET @kol_del = 0

	DECLARE cursor_name CURSOR READ_ONLY FOR
		SELECT
			occ
			,occ_sup
			,fin_id
		FROM @t_occ_sup

	OPEN cursor_name;

	FETCH NEXT FROM cursor_name INTO @occ, @occ_sup, @fin_id;

	WHILE @@fetch_status = 0
	BEGIN
		BEGIN TRAN

			DELETE p
				FROM dbo.PAYM_LIST AS p
			WHERE p.occ = @occ
				AND EXISTS (SELECT
						1
					FROM dbo.SUPPLIERS AS sup
					WHERE sup.sup_id = @sup_id
					AND sup.service_id = p.service_id)

			UPDATE cl
			SET	occ_serv		= NULL
				,account_one	= 0
				,lic_source		= ''
			FROM dbo.CONSMODES_LIST cl
			WHERE cl.occ = @occ
			AND EXISTS (SELECT
					1
				FROM dbo.SUPPLIERS s
				WHERE s.sup_id = @sup_id
				AND s.service_id = cl.service_id)

			DELETE FROM dbo.OCC_SUPPLIERS
			WHERE occ_sup = @occ_sup
				AND fin_id = @fin_id

		COMMIT TRAN

		-- сохраняем в историю изменений
		SET @msg = 'Удаление лицевого поставщика ' + STR(@occ_sup)
		EXEC k_write_log	@occ
							,'удлс'
							,@msg

		SET @kol_del = @kol_del + 1
		FETCH NEXT FROM cursor_name INTO @occ, @occ_sup, @fin_id;

	END

	CLOSE cursor_name;
	DEALLOCATE cursor_name;
go

