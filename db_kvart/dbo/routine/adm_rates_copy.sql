-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Копирование тарифа в другой фин.период
-- =============================================
CREATE   PROCEDURE [dbo].[adm_rates_copy]
(
	@id				INT
	,@fin_id_new	SMALLINT
	,@is_counter	BIT	= 0
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @is_counter IS NULL
		SET @is_counter = 0

	IF @is_counter = 0
	BEGIN
		IF NOT EXISTS (SELECT
					*
				FROM dbo.RATES AS r 
				JOIN dbo.RATES AS r2 
					ON r.finperiod = r2.finperiod
					AND r.tipe_id = r2.tipe_id
					AND r.SERVICE_ID = r2.SERVICE_ID
					AND r.mode_id = r2.mode_id
					AND r.source_id = r2.source_id
					AND r.status_id = r2.status_id
					AND r.proptype_id = r2.proptype_id
				WHERE r.finperiod = @fin_id_new
				AND r2.id = @id)

			INSERT
			INTO RATES
			(	finperiod
				,tipe_id
				,SERVICE_ID
				,mode_id
				,source_id
				,status_id
				,proptype_id
				,value
				,full_value
				,extr_value
				,user_edit)
				SELECT
					@fin_id_new
					,tipe_id
					,SERVICE_ID
					,mode_id
					,source_id
					,status_id
					,proptype_id
					,value
					,full_value
					,extr_value
					,user_edit
				FROM dbo.RATES
				WHERE id = @id

	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT
					*
				FROM dbo.RATES_COUNTER AS r 
				JOIN dbo.RATES_COUNTER AS r2
					ON r.fin_id = r2.fin_id
					AND r.tipe_id = r2.tipe_id
					AND r.SERVICE_ID = r2.SERVICE_ID
					AND r.mode_id = r2.mode_id
					AND r.source_id = r2.source_id
				WHERE r.fin_id = @fin_id_new
				AND r2.id = @id)
			INSERT
			INTO RATES_COUNTER
			(	fin_id
				,tipe_id
				,SERVICE_ID
				,unit_id
				,mode_id
				,source_id
				,tarif
				,user_edit)
				SELECT
					@fin_id_new
					,tipe_id
					,service_id
					,unit_id
					,mode_id
					,source_id
					,tarif
					,user_edit
				FROM dbo.RATES_COUNTER
				WHERE id = @id

	END

END
go

