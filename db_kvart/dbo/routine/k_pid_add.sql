-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_pid_add]
(
	  @fin_id SMALLINT = NULL
	, @occ INT
	, @sup_id INT = NULL
	, @Summa DECIMAL(9, 2) = NULL
	, @pid_tip SMALLINT = 1 -- 1-Уведомление о задолженности, 2- исковое, 3 - соглашение о рассрочке, 4 - претензия, 5-Судебный приказ
	, @occ_sup INT = NULL
	, @data_create SMALLDATETIME = NULL
	, @data_end SMALLDATETIME = NULL
	, @owner_id INT = NULL
	, @is_peny BIT = 1
	, @court_id SMALLINT = NULL -- Код судебного участка
	, @Res SMALLINT = 0 OUTPUT
)
AS
/*
k_pid_add

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @dog_int INT = NULL
		  , @id INT

	IF @is_peny IS NULL
		SET @is_peny = 1

	IF @data_create IS NULL
		SELECT @data_create = dbo.Fun_GetOnlyDate(current_timestamp)
	ELSE
		SELECT @data_create = dbo.Fun_GetOnlyDate(@data_create)

	IF @fin_id IS NULL
		SELECT @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	IF @pid_tip = 1
		AND @data_end IS NULL
		SELECT @data_end = @data_create + 10 -- + 10 дней

	IF @pid_tip = 4 -- Претензия
		SELECT @data_end = NULL

	IF @sup_id > 0
		SELECT @Summa =
					   CASE
						   WHEN @Summa IS NULL THEN SALDO - (PaymAccount - PaymAccount_peny) +
																							  CASE
																								  WHEN @is_peny = 1 THEN Penalty_old_new -- пени(с учётом оплаты) за прошлый месяц  Penalty_old
																								  ELSE 0
																							  END
						   ELSE @Summa
					   END
			 , @dog_int = dog_int
			 , @occ_sup =
						 CASE
							 WHEN @occ_sup IS NULL THEN occ_sup
							 ELSE @occ_sup
						 END
		FROM dbo.Occ_Suppliers 
		WHERE occ = @occ
			AND fin_id = @fin_id
			AND sup_id = @sup_id
	ELSE
		SELECT @Summa =
					   CASE
						   WHEN @Summa IS NULL THEN SALDO - (PaymAccount - PaymAccount_peny) +
																							  CASE
																								  WHEN @is_peny = 1 THEN Penalty_old_new -- пени(с учётом оплаты) за прошлый месяц  Penalty_old
																								  ELSE 0
																							  END
						   ELSE @Summa
					   END
		FROM dbo.View_occ_all_lite 
		WHERE occ = @occ
			AND fin_id = @fin_id

	IF @pid_tip = 1
		AND @dog_int IS NULL
		RETURN

	IF @Summa <= 0
		AND @pid_tip NOT IN (5) -- Для судебного приказа в ручном режиме сумма может быть=0
		RETURN

	IF @owner_id IS NULL
		SELECT @owner_id = p.id
		FROM dbo.People AS p 
		WHERE p.occ = @occ
			AND Fam_id = 'отвл'
			AND Del = 0

	SELECT @id = id
	FROM dbo.Pid 
	WHERE occ = @occ
		AND [data_create] = @data_create
		AND sup_id = COALESCE(@sup_id, 0)
		AND pid_tip = @pid_tip

	IF @id IS NOT NULL
	BEGIN
		UPDATE dbo.Pid
		SET summa = COALESCE(@Summa, 0)
		  , data_end = @data_end
		  , occ_sup = @occ_sup
		  , dog_int = @dog_int
		  , owner_id = @owner_id
		  , sup_id = COALESCE(@sup_id, sup_id)
		  , is_peny = @is_peny
		  , court_id = @court_id
		--,fin_id		= @fin_id
		WHERE id = @id
			AND -- Обновляем если есть изменения
			(COALESCE(data_end, '19000101') <> COALESCE(@data_end, '19000101')
			--OR fin_id <> @fin_id
			OR summa <> COALESCE(@Summa, 0) OR COALESCE(owner_id, 0) <> COALESCE(@owner_id, 0) OR sup_id <> COALESCE(@sup_id, sup_id)
			)
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[Pid] (fin_id
							   , [occ]
							   , [data_create]
							   , [sup_id]
							   , [data_end]
							   , [summa]
							   , [pid_tip]
							   , occ_sup
							   , dog_int
							   , owner_id
							   , is_peny
							   , court_id)
		VALUES(@fin_id
			 , @occ
			 , @data_create
			 , COALESCE(@sup_id, 0)
			 , @data_end
			 , COALESCE(@Summa, 0)
			 , @pid_tip
			 , @occ_sup
			 , @dog_int
			 , @owner_id
			 , @is_peny
			 , @court_id)
		SELECT @id = SCOPE_IDENTITY() -- код нового документа
	END
	SET @Res = @id
END
go

