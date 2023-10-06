CREATE   PROCEDURE [dbo].[k_Get_Koef]
(
	@occ1		 INT
   ,@service_id1 VARCHAR(10)
)
AS
/*
	Возвращаем результирующий коэффициент по лицевому счёту
*/
	SET NOCOUNT ON

	DECLARE @value1 DECIMAL(9,6)

	SET @value1 = 1

	SELECT
		@value1 = @value1 * value
	FROM Koef_occ AS ko
	JOIN Koef AS k
		ON ko.koef_id = k.id
	WHERE ko.occ = @occ1
		AND ko.service_id = @service_id1
		AND k.is_use=1

	SELECT
		'SumKoef' = ROUND(@value1, 3)
go

