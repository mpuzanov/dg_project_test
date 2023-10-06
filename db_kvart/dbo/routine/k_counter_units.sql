CREATE   PROCEDURE [dbo].[k_counter_units]
(
    @service_id1 VARCHAR(10)
)
AS
/*	
	Показываем возможные единицы измерения для счетчиков по услуге
*/	
	SET NOCOUNT ON

	SELECT 
		u.id
		 , u.name
	FROM
		dbo.Units AS u 
		JOIN dbo.Service_units_counter AS su 
			ON u.id = su.unit_id
	WHERE
		su.service_id = @service_id1
go

