-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Помечаем подозрительные показания счетчиков
-- =============================================
CREATE           PROCEDURE [dbo].[k_counter_inspector_alert]
(
	  @fin_id SMALLINT = NULL
	, @counter_id INT = NULL
	, @flat_id INT = NULL
	, @tip_id SMALLINT = NULL
	, @debug BIT = NULL
)
AS
/*
exec k_counter_inspector_alert @fin_id=250, @debug=1
exec k_counter_inspector_alert @debug=1
*/
BEGIN

	SET NOCOUNT ON;

	UPDATE ci
	SET warning =
				 CASE
					 WHEN ABS(ci.value_vday) > t.alert_value_vday THEN 'ALERT'
					 WHEN ABS(ci.actual_value) > t.alert_value_month THEN 'ALERT'
				 END
	FROM dbo.Counter_inspector AS ci
		JOIN dbo.Counters AS c ON 
			c.id = ci.counter_id
		JOIN dbo.Buildings AS b ON 
			c.build_id = b.id
		JOIN dbo.Occupation_Types AS ot ON 
			b.tip_id = ot.id
		JOIN (SELECT * FROM dbo.Fun_GetCounterServValueLimits()) AS t ON 
			c.service_id = t.service_id
	WHERE 
		(ci.fin_id = COALESCE(@fin_id, b.fin_current))
		AND c.is_build = CAST(0 AS BIT)
		AND COALESCE(ci.warning, 'ALERT') = 'ALERT'
		AND (@counter_id IS NULL OR c.id = @counter_id)
		AND (@tip_id IS NULL OR ot.id = @tip_id)
		AND (@flat_id IS NULL OR c.flat_id = @flat_id)

	IF @debug = 1
	BEGIN		
		SELECT c.service_id
			 , cl.occ
			 , ci.*
		FROM dbo.Counter_inspector AS ci 
			JOIN dbo.Counters AS c 
				ON c.id = ci.counter_id
			JOIN dbo.Counter_list_all AS cl 
				ON cl.fin_id = ci.fin_id
				AND cl.counter_id = c.id
			JOIN dbo.Buildings AS b 
				ON c.build_id = b.id
			JOIN dbo.Occupation_Types AS ot 
				ON b.tip_id = ot.id
		WHERE 
			(ci.fin_id = COALESCE(@fin_id, b.fin_current))
			AND ci.warning = 'ALERT'
			AND (@tip_id IS NULL OR ot.id = @tip_id)
			AND (@flat_id IS NULL OR c.flat_id = @flat_id)

		SELECT * FROM dbo.Fun_GetCounterServValueLimits()
	END
END
go

