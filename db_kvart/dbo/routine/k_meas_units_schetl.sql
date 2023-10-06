CREATE   PROCEDURE [dbo].[k_meas_units_schetl]
(
    @occ1        INT,
    @serv1       VARCHAR(10) = NULL,
    @is_counter1 BIT        = 0, -- по счетчикам
    @fin_id      SMALLINT   = NULL
)
AS
/*
Выдаем нормы по режимам потребления по лицевому счету
дата создания: 11.01.2011
автор: Пузанов М.А.

exec k_meas_units_schetl @occ1=33001, @is_counter1=0
exec k_meas_units_schetl @occ1=33001, @is_counter1=1

*/
	SET NOCOUNT ON

	IF @is_counter1 IS NULL
		SET @is_counter1 = 0

	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @is_counter1 = 0
	BEGIN
		SELECT s.name AS 'Услуга'
			 , u.name AS 'Ед.измерения'
			 , cm.name AS 'Режим потребления'
			 , mu.q_single AS 'один'
			 , mu.two_single AS 'два'
			 , mu.three_single AS 'три'
			 , mu.four_single AS 'четыре'
			 , mu.q_member AS '5 и более'
			 , mu.norma_extr_tarif
			 , mu.norma_full_tarif
			 , [o].[address]
		FROM
			dbo.Occupations AS o 
			JOIN dbo.Consmodes_list AS cl 
				ON o.Occ = cl.occ
			JOIN dbo.cons_modes AS cm 
				ON cl.mode_id = cm.id
			JOIN dbo.measurement_units AS mu 
				ON cm.id = mu.mode_id AND o.tip_id = mu.tip_id
			JOIN dbo.units AS u 
				ON mu.unit_id = u.id
			JOIN dbo.service_units AS su 
				ON cm.service_id = su.service_id AND mu.unit_id = su.unit_id AND o.tip_id = su.tip_id AND mu.fin_id = su.fin_id AND su.roomtype_id = o.ROOMTYPE_ID
			JOIN dbo.SERVICES AS s
				ON cm.service_id = s.id
		WHERE
			o.Occ = @occ1
			AND (@serv1 IS NULL OR cm.service_id = @serv1)						
			AND su.fin_id = @fin_id
			AND (mu.q_single<>0 OR mu.two_single<>0 OR mu.three_single<>0 OR mu.four_single<>0 OR mu.q_member<>0 OR mu.norma_extr_tarif<>0)
			AND mu.is_counter = 0
		ORDER BY
			s.name, mu.mode_id
	END

	IF @is_counter1 = 1
	BEGIN
		SELECT s.name AS 'Услуга'
			 , u.name AS 'Ед.измерения'
			 , cm.name AS 'Режим потребления'
			 , mu.q_single AS 'один'
			 , mu.two_single AS 'два'
			 , mu.three_single AS 'три'
			 , mu.four_single AS 'четыре'
			 , mu.q_member AS '5 и более'
			 , mu.norma_extr_tarif
			 , mu.norma_full_tarif
			 , [o].[address]
		FROM
			dbo.Occupations AS o 
			JOIN dbo.Consmodes_list AS cl 
				ON o.Occ = cl.occ
			JOIN dbo.cons_modes AS cm 
				ON cl.mode_id = cm.id
			JOIN dbo.measurement_units AS mu 
				ON cm.id = mu.mode_id AND o.tip_id = mu.tip_id
			JOIN dbo.units AS u 
				ON mu.unit_id = u.id
			JOIN dbo.service_units_counter AS su  -- Другая таблица с верхним запросом
				ON cm.service_id = su.service_id AND mu.unit_id = su.unit_id
			JOIN dbo.SERVICES AS s
				ON cm.service_id = s.id
		WHERE
			o.Occ = @occ1
			AND (@serv1 IS NULL OR cm.service_id = @serv1)
			AND mu.is_counter = 1
			AND mu.fin_id = @fin_id
			AND (mu.q_single<>0 OR mu.two_single<>0 OR mu.three_single<>0 OR mu.four_single<>0 OR mu.q_member<>0 OR mu.norma_extr_tarif<>0)
		ORDER BY
			s.name, mu.mode_id
	END
go

