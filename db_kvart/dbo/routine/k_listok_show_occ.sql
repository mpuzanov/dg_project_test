CREATE   PROCEDURE [dbo].[k_listok_show_occ]
(
	@occ1 INT
)
AS
	/*

Показываем информацию для формирования листка убытия

*/
	SET NOCOUNT ON

	DECLARE @CurrentDate DATETIME
	SET @CurrentDate = current_timestamp

	SELECT
		pl.id
		,pl.occ
		,pl.last_name + ' ' + pl.first_name + ' ' + pl.second_name AS Initials
		,dbo.Fun_GetBetweenDateYear(pl.birthdate, @CurrentDate) AS Age-- кол-во лет человеку
		,DateCreate
		,CASE
			WHEN pl.listok_id = 1 THEN 'Прибытия'
			ELSE 'Убытия'
		END AS 'Listok'
	FROM dbo.People_listok AS pl 
	WHERE occ = @occ1
go

