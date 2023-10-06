CREATE   PROCEDURE [dbo].[rep_rates]
(
	@fin_id1	 INT		= NULL
   ,@tipe_id1	 SMALLINT	= NULL
   ,@service_id1 VARCHAR(10)= NULL
)
AS
/*
	Выдаем тарифы по услуге
	если по умолчанию то выдаем список всех тарифов за последний фин. период
	rep_rates 227, 1
*/

	SET NOCOUNT ON

	IF @service_id1 = ''
		OR @service_id1 = '0'
		SET @service_id1 = NULL

	IF @fin_id1 IS NULL
		OR @fin_id1 = ''
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(@tipe_id1, NULL, NULL, NULL)
	--if @tipe_id1 is null or @tipe_id1=''
	--   select @tipe_id1=1

	SELECT
		r.id
	   ,r.finperiod
	   ,gb.StrMes
	   ,ot.Name AS tipe_name
	   ,r.service_id
	   ,r.status_id
	   ,r.proptype_id
	   ,s.Name AS service_name
	   ,cm.id AS mode_id
	   ,cm.Name AS modes
	   ,r.source_id
	   ,su.Name AS suppliers
	   ,r.value	   
	   ,r.extr_value
	   ,r.full_value
	   ,r.date_edit
		--,user_edit = U.Initials
	   ,user_edit_last = (SELECT TOP (1)
				CONCAT(U2.Initials , ' (' , cp.StrFinPeriod , ')')
			FROM dbo.RATES AS r2 
			JOIN dbo.USERS AS U2 
				ON r2.user_edit = U2.id
			JOIN CALENDAR_PERIOD cp
				ON cp.fin_id = r2.finperiod
			WHERE r2.id=r.id			
			ORDER BY r2.finperiod DESC)
	FROM dbo.RATES AS r
		JOIN dbo.VOCC_TYPES AS ot 
			ON r.tipe_id = ot.id
		JOIN dbo.GLOBAL_VALUES AS gb 
			ON r.finperiod = gb.fin_id
		JOIN dbo.View_SERVICES AS s 
			ON r.service_id = s.id
		JOIN dbo.CONS_MODES AS cm 
			ON r.mode_id = cm.id
		JOIN dbo.View_SUPPLIERS AS su 
			ON r.source_id = su.id
		LEFT JOIN dbo.USERS AS U
			ON r.user_edit = U.id
	WHERE r.finperiod = @fin_id1
		AND (@tipe_id1 is NULL or r.tipe_id = @tipe_id1)
		AND (@service_id1 IS NULL or r.service_id = @service_id1)
		AND (r.value<> 0 OR r.extr_value <> 0 OR r.full_value <> 0)
	ORDER BY r.tipe_id, s.Name, cm.id, r.source_id
go

