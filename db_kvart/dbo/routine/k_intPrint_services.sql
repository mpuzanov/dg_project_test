CREATE   PROCEDURE [dbo].[k_intPrint_services]
(
	@occ1			INT
	,@account_type1	SMALLINT	= 0
)
AS
	/*
	
	Выдаем список услуг для печати квитанций
	
	k_intPrint_services 0, null
	k_intPrint_services 680002972, 0
	k_intPrint_services 680002972, 1
	k_intPrint_services 680002972, 2
	k_intPrint_services 680002972, 3

	*/
	SET NOCOUNT ON

	if @account_type1 is null
		set @account_type1=0

	-- Единая квитанция
	IF @account_type1 = 0
	BEGIN
		SELECT
			'id' = '????'
			,'name' = 'Все услуги'
			,'source_id' = 0
			,'id_accounts' = 0
	END

	-- Квитанция по отдельной услуге
	IF @account_type1 = 1
	BEGIN
		SELECT
			s.id
			,s.name
			,cl.source_id
			,sup.id_accounts
		FROM dbo.CONSMODES_LIST AS cl 
		JOIN dbo.View_SERVICES AS s 
			ON cl.service_id = s.id
		JOIN dbo.View_SUPPLIERS AS sup 
			ON cl.source_id = sup.id
		WHERE cl.occ = @occ1
		AND cl.account_one = 1
		ORDER BY s.service_no
	END

	-- Квитанция по счетчику
	IF @account_type1 = 2
	BEGIN
		SELECT
			s.id
			,s.name
			,cl.source_id
			,sup.id_accounts
		FROM dbo.CONSMODES_LIST AS cl 
		JOIN dbo.View_SERVICES AS s 
			ON cl.service_id = s.id
		JOIN dbo.View_SUPPLIERS AS sup 
			ON cl.source_id = sup.id
		WHERE cl.occ = @occ1
		AND cl.is_counter = 1
		ORDER BY s.service_no
	END

	-- Квитанция по поставщику услуге
	IF @account_type1 = 3
	BEGIN
		SELECT
			s.id
			,s.name
			,cl.source_id
			,sup.id_accounts
		FROM dbo.CONSMODES_LIST AS cl 
		JOIN dbo.View_SERVICES AS s 
			ON cl.service_id = s.id
		JOIN dbo.SUPPLIERS_ALL AS sup 
			ON cl.sup_id = sup.id
		WHERE cl.occ = @occ1
		AND cl.account_one = 1
		ORDER BY s.service_no
	END
go

