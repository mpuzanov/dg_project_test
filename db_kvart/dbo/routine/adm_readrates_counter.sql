CREATE   PROCEDURE [dbo].[adm_readrates_counter]
(
	@fin_id1	 SMALLINT -- фин.период
   ,@tipe_id1	 SMALLINT -- тип жилого фонда
   ,@service_id1 VARCHAR(10) -- код услуги
   ,@unit_id1	 VARCHAR(10) -- Единица измерения
   ,@source_id1	 INT = 0  -- Поставщик
   ,@mode_id1	 INT = 0  -- Режим потребления
)
AS

SET NOCOUNT ON

SELECT tarif
	 , extr_tarif
	 , full_tarif
FROM dbo.Rates_counter
WHERE fin_id = @fin_id1
	AND tipe_id = @tipe_id1
	AND service_id = @service_id1
	AND unit_id = @unit_id1
	AND source_id = COALESCE(@source_id1, 0)
	AND mode_id = COALESCE(@mode_id1, 0)
go

