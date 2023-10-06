-- =============================================
-- Author:		Пузанов
-- Create date: 28.08.2012
-- Description:	Загрузка данных сальдо по услугам   используется в АРМ Экспорт
-- =============================================
CREATE     PROCEDURE [dbo].[adm_load_saldo_serv]
	@fin_id			SMALLINT
	,@occ			INT
	,@saldo			DECIMAL(9, 2)	= NULL
	,@service_id	VARCHAR(10)		= NULL
	,@Rec_update	SMALLINT		= 0 OUTPUT
	,@Rec_add		BIT				= 1 -- суммировать новое сальдо с текщим
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @occ_sup INT, @sup_id int

	IF @Rec_add IS NULL
		SET @Rec_add = 1;
	
	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE occ = @occ)
	BEGIN
		SET @occ_sup = @occ;
		SET @occ = NULL;

		SELECT TOP 1
			@occ = occ, @sup_id=sup_id
		FROM dbo.OCC_SUPPLIERS AS OS 
		WHERE occ_sup = @occ_sup
		AND fin_id <= @fin_id
		ORDER BY fin_id desc;

		IF @occ IS NULL
			RETURN;

	END;

	-- если лицевой закрыт - то не меняем сальдо
	IF EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE occ = @occ
			AND status_id = 'закр')
		RETURN;
	--PRINT @occ	
	-- обновляем сальдо

	IF EXISTS (SELECT
				1
			FROM dbo.PAYM_LIST 
			WHERE occ = @occ
			AND service_id = @service_id)
	BEGIN
		IF @Rec_add = 1
			UPDATE dbo.PAYM_LIST
			SET SALDO = SALDO + @saldo
			WHERE occ = @occ
			AND service_id = @service_id;
		ELSE
			UPDATE dbo.PAYM_LIST 
			SET SALDO = @saldo
			WHERE occ = @occ
			AND service_id = @service_id;
	END;
	ELSE
	BEGIN
		INSERT
		INTO dbo.PAYM_LIST
		(	occ
			,service_id
			,sup_id
			,SALDO
			,Value
			,Added
			,Paid
			,PaymAccount
			,account_one
			,fin_id)
		VALUES (@occ, @service_id, COALESCE(@sup_id,0), @saldo, 0, 0, 0, 0, 0, @fin_id);
	END;


	UPDATE dbo.OCCUPATIONS 
	SET saldo_edit = 1
	WHERE occ = @occ;

	SELECT
		@Rec_update = @@rowcount;

END;
go

