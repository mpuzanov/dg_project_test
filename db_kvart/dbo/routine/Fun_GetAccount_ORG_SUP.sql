-- =============================================
-- Author:		Пузанов
-- Create date: 24.08.2011
-- Description:	Возвращаем банковский счет для квитанции поставщика
-- Пример вызова:  select * from dbo.Fun_GetAccount_ORG(@t, 123)
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAccount_ORG_SUP]
(
	@intable	dbo.myTypeTableOcc	READONLY
	,@sup_id	INT
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
	,BANK				VARCHAR(50)
	,korschet			VARCHAR(20)
	,inn				VARCHAR(12)
	,id_barcode			VARCHAR(50)
	,name_str2			VARCHAR(100)
	,tip_account_org	SMALLINT
	,BARCODE_TYPE		SMALLINT
	,kpp				VARCHAR(9)
	,cbc				VARCHAR(20)
	,oktmo				VARCHAR(11)
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
		,BANK
		,korschet
		,inn
		,id_barcode
		,name_str2
		,tip_account_org
		,BARCODE_TYPE
		,kpp
		,cbc
		,oktmo)
			SELECT
				ao.id
				,t.occ
				,t.service_id
				,ao.rasschet
				,ao.bik
				,ao.licbank
				,ao.name_str1
				,ao.BANK
				,ao.korschet
				,ao.inn
				,COALESCE(ao.id_barcode, '')
				,ao.name_str2
				,ao.tip
				,ao.BARCODE_TYPE
				,ao.kpp
				,ao.cbc
				,ao.oktmo
			FROM	@intable AS t
					,dbo.SUPPLIERS_ALL AS s 
					JOIN dbo.ACCOUNT_ORG AS ao
						ON s.bank_account = ao.id
			WHERE s.id = @sup_id

	RETURN
END
go

