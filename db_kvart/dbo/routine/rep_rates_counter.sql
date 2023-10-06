CREATE   PROCEDURE [dbo].[rep_rates_counter]
(
    @fin_id1     INT        = NULL,
    @tipe_id1    SMALLINT   = NULL,
    @service_id1 VARCHAR(10)= NULL
)
AS
	/*
  Выдаем тарифы по счетчикам

дата создания: 25.04.2004
18.01.07
автор: Пузанов М.А.

rep_rates_counter 243, 4, 'хвод'
*/
	SET NOCOUNT ON

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tipe_id1, NULL, NULL, NULL)

	SELECT r.id
		 , r.fin_id
		 , gb.strmes
		 , ot.name AS tipe_name
		 , r.service_id
		 , s.name AS service_name
		 , u.name AS unit_name
		 , r.tarif
		 , r.extr_tarif
		 , r.full_tarif
		 , sup.name AS supliers
		 , cm.name AS modes
		 --, US.Initials AS user_edit
		 , r.date_edit
		 , user_edit_last = (SELECT TOP (1)
							CONCAT(U2.Initials , ' (' , cp.StrFinPeriod , ')')
						FROM dbo.RATES_COUNTER AS r2 
						JOIN dbo.USERS AS U2 
							ON r2.user_edit = U2.id
						JOIN dbo.CALENDAR_PERIOD cp 
							ON cp.fin_id = r2.fin_id
						WHERE r2.id=r.id			
						ORDER BY r2.fin_id DESC)
	FROM dbo.RATES_COUNTER AS r 
		LEFT JOIN dbo.View_SUPPLIERS AS sup 
			ON r.source_id = sup.id
		LEFT JOIN dbo.CONS_MODES AS cm 
			ON r.mode_id = cm.id
		JOIN dbo.VOCC_TYPES AS ot 
			ON r.tipe_id = ot.id
		JOIN dbo.global_values AS gb 
			ON r.fin_id = gb.fin_id
		JOIN dbo.View_services AS s 
			ON r.service_id = s.id
		JOIN dbo.units AS u 
			ON r.unit_id = u.id
		LEFT JOIN dbo.USERS AS US 
			ON r.user_edit = US.id			
	WHERE r.fin_id = @fin_id1
		AND (tipe_id = @tipe_id1 OR @tipe_id1 IS NULL)
		AND (r.service_id = @service_id1 OR @service_id1 IS NULL)
go

