-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Раскидать переплату в сальдо с помощью разовых
-- =============================================
CREATE     PROCEDURE [dbo].[k_saldo_added_overpayment]
(
@occ1 INT
, @sup_id INT = 0
, @add_type SMALLINT = 17 --Тех корректировка (нет в ПД)
, @debug BIT = 0
)
AS
/*
-- запрос для поиска примеров лицевых
SELECT o.Occ, o.address, o.SALDO
from Occupations as o
WHERE o.SALDO=0 and o.Value=0
AND EXISTS(SELECT 1 from Paym_list as pl WHERE pl.occ=o.occ AND pl.fin_id=o.fin_id and pl.saldo<0)
ORDER BY o.fin_id DESC


exec k_saldo_added_overpayment @occ1=13004, @debug=1
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	SELECT @add_type=COALESCE(@add_type,17)
		, @sup_id=COALESCE(@sup_id,0)

	DECLARE @doc VARCHAR(100) = N'перенос сальдо'
		  , @doc_no VARCHAR(10) = '885'
		  , @doc_date DATE = current_timestamp
		  , @user_edit INT = dbo.Fun_GetCurrentUserId()
		  , @fin_id SMALLINT = dbo.Fun_GetFinCurrent(null,null,null,@occ1)

	DECLARE @Saldo DECIMAL(15, 2) = 0
		, @SumMinus DECIMAL(15, 2) = 0
		, @SumPlus DECIMAL(15, 2) = 0
		--, @koef DECIMAL(15, 6) = 1

	IF EXISTS(SELECT * FROM dbo.Added_Payments WHERE occ=@occ1 AND sup_id=@sup_id AND doc_no=@doc_no)
	BEGIN
		RAISERROR('Уже существуют разовые по корректировке сальдо',16,1);	
		RETURN
	END

	SELECT service_id, saldo, CAST(0 as DECIMAL(15, 2)) as added
	INTO #t
	FROM dbo.Paym_list
	WHERE occ=@occ1
	AND sup_id=@sup_id
	AND fin_id=@fin_id
	AND saldo<>0

	SELECT @Saldo=sum(saldo)
	, @SumMinus = sum(CASE
                          WHEN saldo < 0 THEN saldo
                          ELSE 0
        END)
	, @SumPlus = sum(CASE
                         WHEN saldo > 0 THEN saldo
                         ELSE 0
        END)
	FROM #t;
	
	IF @SumPlus=0 OR @SumMinus=0
	BEGIN
		RAISERROR('Положительное и отрицательное сальдо по услугам должно быть',16,1);
		RETURN
	END
	IF abs(@SumMinus)>@SumPlus
	BEGIN
		RAISERROR('Отрицательное сальдо по услугам должно быть меньше или равно положительному',16,1);
		RETURN
	END

	if @debug=1
		SELECT @Saldo, @SumMinus, @SumPlus;

	if @Saldo=0 -- @SumMinus = @SumPlus
		UPDATE t SET added = Saldo * @SumMinus / @SumPlus FROM #t as t
	ELSE
		BEGIN   -- @SumMinus < @SumPlus
			UPDATE t SET added = -Saldo FROM #t t where saldo<0
			UPDATE t SET added = Saldo * @SumMinus / @SumPlus FROM #t as t where saldo>0

			-- раскидываем остаток
			Update t SET added = added + (@SumMinus-(Select Sum(added) From #t where saldo>0))
			from #t t
			Where service_id=(SELECT top(1) service_id from #t where saldo>0 ORDER BY added DESC)
		END
	
	if @debug=1
	BEGIN
		SELECT *, (saldo + added) as debt from #t
		SELECT Saldo=sum(saldo)		
		FROM #t;
	END;

	-- добавляем разовые на плюс
		INSERT INTO dbo.Added_Payments (fin_id
								  , Occ
								  , service_id
								  , sup_id
								  , add_type
								  , value
								  , doc
								  , doc_no
								  , doc_date
								  , user_edit
								  , date_edit)
		SELECT @fin_id
			 , @Occ1
			 , service_id
			 , @sup_id
			 , @add_type
			 , added
			 , @doc
			 , @doc_no
			 , @doc_date
			 , @user_edit
			 , current_timestamp
		FROM #t

END
go

