-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[ws_show_counters]
(
	  @occ INT
)
AS
/*
exec ws_show_counters 33100
exec ws_show_counters 350033100
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
		  , @tip_id SMALLINT

	SELECT @fin_current = o.fin_id
		 , @tip_id = o.tip_id
	FROM dbo.Occupations o
	WHERE o.occ = @occ

	IF @fin_current IS NULL
		SELECT @occ = o.occ
			 , @fin_current = o.fin_id
			 , @tip_id = o.tip_id
		FROM dbo.Occ_Suppliers os 
			JOIN dbo.Occupations AS o 
				ON os.occ = o.occ
				AND os.fin_id = o.fin_id
		WHERE os.occ_sup = @occ
	IF @@rowcount = 0
	BEGIN
		SELECT @occ = dbo.Fun_GetFalseOccIn(@occ)
		SELECT @fin_current = o.fin_id
			 , @tip_id = o.tip_id
		FROM dbo.Occupations o
		WHERE o.occ = @occ
	END

	--PRINT @occ
	--PRINT @fin_current
/*
    lic: int  # лицевой
    counter_id: int  # код ПУ
    serv_name: str  # услуга
    service_id: str  # код услуги в БД
    serial_number: str  # серийный номер ПУ
    type: str  # марка ПУ
    max_value: int  # максимальное значения показания ПУ
    unit_id: str  # единица измерения
    count_value: Decimal  # показание ПУ при установке
    date_create: date  # дата установки
    PeriodCheck: date  # период поверки
    value_date: date  # дата последнего учтённого показания
    last_value: Decimal  # значение последнего учтённого показания
    actual_value: Decimal  # объём последнего учтённого показания
    avg_month: Decimal  # средний объём в месяц
    tarif: Decimal  # текущий тариф
    NormaSingle: Decimal  # норматив
    avg_itog: Decimal  #
    kol_norma: Decimal  # NormaSingle * kol_people
*/
	SELECT c.id AS counter_id
		 , cl.occ AS lic
		 , cl.occ
		 , c.service_id
		 , c.serial_number
		 , c.type
		 , c.build_id
		 , c.flat_id
		 , c.max_value
		 , c.Koef
		 , c.unit_id
		 , c.count_value AS count_value
		 , CAST(c.date_create AS DATE) AS date_create
		 , c.CountValue_del AS count_value_del
		 , CAST(c.date_del AS DATE) AS date_del
		 , CAST(c.PeriodCheck AS DATE) AS PeriodCheck
		 , c.date_edit
		 , c.comments
		 , c.is_build
		 , cl.occ_counter
		 , s.name AS serv_name
		 , CASE
			   WHEN c.date_del IS NULL THEN 'Работает'
			   ELSE 'Закрыт'
		   END AS closed
		 , CASE
			   WHEN cl.kol_occ <= 1 THEN 'Индивидуальный'
			   WHEN COALESCE(c.room_id, 0) > 0 THEN 'Комнатный'
			   ELSE 'Общий (квартирный)'
		   END AS count_occ
		 , cl.kol_occ
		 , cp.StrFinPeriod AS fin_period
		 , cl.fin_id AS fin_id
		 , o.address AS [address]
		 , cl.internal
		 , u.Initials AS Initial_user
		 , c.mode_id
		 , COALESCE(cm.name, 'Текущий') AS mode_name
		 , s.sort_no
		 , cl.KolmesForPeriodCheck
		 , cl.avg_vday
		 , c.id_pu_gis
		 , c.is_sensor_temp
		 , c.is_sensor_press
		 , c.PeriodLastCheck
		 , c.PeriodInterval AS PeriodInterval
		 , c.is_remot_reading
		 , c.room_id
		 , c.ReasonDel
		 , ci_last.inspector_value AS last_value
		 , CAST(ci_last.inspector_date AS DATE) AS value_date
		 , ci_last.actual_value
		 , ci_last.tarif
		 , COALESCE(cl.no_vozvrat, 0) AS no_vozvrat
		 , CAST(c.counter_uid AS VARCHAR(36)) AS counter_uid
		 , c.count_tarif
		 , c.value_serv_many_pu
	FROM dbo.Counters AS c 
		JOIN dbo.Counter_list_all AS cl 
			ON c.id = cl.counter_id
		JOIN dbo.View_services AS s 
			ON cl.service_id = s.id
		LEFT JOIN dbo.Users u 
			ON c.user_edit = u.id
		JOIN dbo.Calendar_period cp 
			ON cp.fin_id = cl.fin_id
		LEFT JOIN dbo.Occupations o 
			ON cl.occ = o.occ
		LEFT JOIN dbo.Cons_modes AS cm 
			ON c.mode_id = cm.id
			AND c.service_id = cm.service_id
		OUTER APPLY [dbo].Fun_GetCounterValue_last(c.id, @fin_current) AS ci_last
	WHERE cl.Occ = @occ
		AND (cl.fin_id = @fin_current OR @fin_current IS NULL)
	ORDER BY fin_id DESC
		   , s.sort_no

END
go

