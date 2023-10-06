CREATE   PROCEDURE [dbo].[k_paydoc_delete]
(
	  @id1 INT -- Код пачки которую надо удалить
	, @success BIT = 0 OUTPUT
)
AS
	--
	--  Если пачка не закрыта то её можно удалять
	--
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SET @success = 0

	DECLARE @forwarded1 BIT
		  , @err INT
		  , @sum1 MONEY
		  , @fin_id SMALLINT
		  , @date_pack SMALLDATETIME
		  , @tip_name VARCHAR(50)
		  , @sup_name VARCHAR(50)
		  , @bank_name VARCHAR(50)

	SELECT @forwarded1 = pd.forwarded
		 , @fin_id = pd.fin_id
		 , @date_pack = pd.day
		 , @sum1 = pd.total
		 , @tip_name = ot.name
		 , @sup_name = sa.name
		 , @bank_name = vpo.bank_name
	FROM dbo.Paydoc_packs AS pd 
		LEFT JOIN dbo.View_paycoll_orgs vpo ON 
			pd.fin_id = vpo.fin_id
			AND pd.source_id = vpo.id
		LEFT JOIN dbo.Occupation_Types ot ON 
			pd.tip_id = ot.id
		LEFT JOIN dbo.Suppliers_all sa ON 
			pd.sup_id = sa.id
	WHERE pd.id = @id1;

	IF @forwarded1 = 1
	BEGIN
		RAISERROR ('Удалить можно только не закрытую пачку!', 11, 1)
		RETURN 1
	END

	BEGIN TRAN

		DELETE PS 
		FROM dbo.Payings p
			JOIN dbo.Paying_serv AS PS ON 
				p.id = PS.paying_id
		WHERE p.pack_id = @id1

		DELETE dbo.Payings 
		WHERE pack_id = @id1

		DELETE dbo.Paydoc_packs 
		WHERE id = @id1

		UPDATE dbo.Bank_Dbf 
		SET pack_id = NULL
		WHERE pack_id = @id1

		SET @success = 1

	COMMIT TRAN

	-- сохраняем в историю изменений
	DECLARE @str1 VARCHAR(100)
	SET @str1 = 'пачка №:' + LTRIM(STR(@id1)) + ' на сумму:' + LTRIM(STR(@sum1, 11, 2))
	SET @str1 = @str1 + ' за дату:' + CONVERT(VARCHAR(12), @date_pack, 104)
	SET @str1 = @str1 + ', ' + @bank_name + ', ' + @tip_name + ', ' + @sup_name
	EXEC k_write_log_adm 'упач'
						, @str1
go

