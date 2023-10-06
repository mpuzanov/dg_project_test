CREATE   PROCEDURE [dbo].[rep_build_dog]
(
	@fin_id		SMALLINT
	,@sup_id	INT			= NULL
	,@tip_id	SMALLINT	= NULL
	,@dog_id	VARCHAR(8)	= NULL
)
/*
Список домов по договору
*/
AS
BEGIN
	SET NOCOUNT ON;

	--IF @fin_id IS NULL AND @tip_id IS NOT NULL
	--	SELECT @fin_id=dbo.Fun_GetFinCurrent(@tip_id,NULL,NULL,NULL)

	SELECT
		dog.dog_id
		,db.fin_id
		,[build_id]
		,[dog_name]
		,dog.id
		,[dog_date]
		,ot.name AS tip_name
		,sup.name AS sup_name
		,b.adres
		,b.KolLic
		--,b.KolFlats
		--,b.KolPeople
		--,b.Total_sq
		,ao.rasschet
		,ao.bik
		,ao.korschet
		,ao.BANK
		,ao.name_str1
		,ao.inn
		,ao.kpp
	FROM [dbo].[DOG_BUILD] AS db 
	JOIN dbo.DOG_SUP AS dog 
		ON db.dog_int = dog.id
	JOIN dbo.VOCC_TYPES AS ot 
		ON dog.tip_id = ot.id
	JOIN dbo.View_SUPPLIERS_ALL AS sup 
		ON dog.sup_id = sup.id
	JOIN dbo.View_BUILDINGS AS b 
		ON db.build_id = b.id
	LEFT JOIN dbo.ACCOUNT_ORG ao 
		ON dog.bank_account = ao.id
	WHERE db.fin_id = COALESCE(@fin_id, b.fin_current)
	AND (dog.dog_id = @dog_id OR @dog_id IS NULL)
	AND (sup_id = @sup_id OR @sup_id IS NULL)
	AND (dog.tip_id = @tip_id OR @tip_id is null)
	ORDER BY b.street_name, b.nom_dom_sort
END
go

