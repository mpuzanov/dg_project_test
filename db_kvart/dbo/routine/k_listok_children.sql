CREATE   PROCEDURE [dbo].[k_listok_children]
(
	@id1			INT
	,@listok_id1	SMALLINT
)
AS
	/*
	
	Показываем информацию по детям у выбранного человека
	для формирования листка прибытия или убытия
	
	*/
	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE @occ1 INT

	SELECT
		@occ1 = occ
	FROM dbo.People_listok AS pl 
	WHERE id = @id1

	SELECT
		last_name
		,first_name
		,second_name
		,CASE
			WHEN sex = 1 THEN 'муж'
			WHEN sex = 0 THEN 'жен'
			ELSE '   '
		END AS sex
		,birthdate  --=convert(char(14), Birthdate, 106)
	FROM dbo.People_listok AS pl 
	WHERE occ = @occ1
	AND OwnerParent = @id1
	AND listok_id = @listok_id1
go

