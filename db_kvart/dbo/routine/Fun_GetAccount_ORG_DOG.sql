-- =============================================
-- Author:		Пузанов
-- Create date: 24.08.2011
-- Description:	Возвращаем банковский счет для квитанции по договору
-- Пример вызова:  select * from dbo.Fun_GetAccount_DOG(@t, 123)
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetAccount_ORG_DOG]
(
	@intable	dbo.myTypeTableOcc	READONLY
	,@dog_int	INT
)
RETURNS @t1 TABLE
(
	id					INT
	,occ				INT
	,service_id			VARCHAR(10)	DEFAULT NULL
	,rasschet			VARCHAR(20)
	,bik				VARCHAR(9)
	,licbank			BIGINT
	,name_str1			VARCHAR(100)
	,bank				VARCHAR(50)
	,korschet			VARCHAR(20)
	,inn				VARCHAR(12)
	,id_barcode			SMALLINT
	,name_str2			VARCHAR(100)
	,tip_account_org	SMALLINT
	,barcode_type		SMALLINT
	,kpp				VARCHAR(9)
	,cbc				VARCHAR(20)
	,oktmo				VARCHAR(11)
	,BankRasschetStr	VARCHAR(1000)
)
AS
BEGIN


	-- Поставщик	
	INSERT INTO @t1
	(	id
		,occ
		,service_id
		,rasschet
		,bik
		,licbank
		,name_str1
		,bank
		,korschet
		,inn
		,id_barcode
		,name_str2
		,tip_account_org
		,barcode_type
		,kpp
		,cbc
		,oktmo
		,BankRasschetStr)
			SELECT
				ao.id
				,t.occ
				,t.service_id
				,ao.rasschet
				,ao.bik
				,ao.licbank
				,ao.name_str1
				,ao.bank
				,ao.korschet
				,ao.inn
				,COALESCE(ao.id_barcode, '')
				,ao.name_str2
				,ao.tip
				,ao.barcode_type
				,ao.kpp
				,ao.cbc
				,ao.oktmo
				,CASE
					WHEN (ao.kpp <> '') 
					THEN 
					CONCAT(ao.name_str1 , ' ИНН ' , ao.inn , ' Р/С ' , ao.rasschet , ' В ' , ao.bank , ' К/С ' , ao.korschet ,' БИК ' , ao.bik)
					ELSE 
					CONCAT(ao.name_str1 , ' ИНН ' , ao.inn , ' КПП ' , ao.kpp , ' Р/С ' , ao.rasschet , ' В ' , ao.bank , ' К/С ' , ao.korschet , ' БИК ' , ao.bik)
				END
			FROM @intable AS t
					,dbo.DOG_SUP AS dg 
					JOIN dbo.ACCOUNT_ORG AS ao
						ON dg.bank_account = ao.id
			WHERE dg.id = @dog_int



	RETURN
END
go

