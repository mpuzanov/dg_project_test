CREATE   PROCEDURE [dbo].[adm_readrates]
(
	@finPeriod1	  SMALLINT -- фин.период
   ,@tipe_id1	  SMALLINT -- тип жилого фонда
   ,@service_id1  VARCHAR(10)  -- код услуги
   ,@mode_id1	  INT -- код режима потребления
   ,@source_id1	  INT  -- код поставщика
   ,@status_id1	  VARCHAR(10) -- статус лицевого счета(откр, своб, закр)
   ,@proptype_id1 VARCHAR(10) -- статус квартиры (непр, прив, купл, арен )
)
AS

SET NOCOUNT ON

SELECT value
	 , full_value
	 , extr_value
FROM dbo.Rates 
WHERE finperiod = @finPeriod1
	AND tipe_id = @tipe_id1
	AND service_id = @service_id1
	AND mode_id = @mode_id1
	AND source_id = @source_id1
	AND status_id = @status_id1
	AND proptype_id = @proptype_id1
go

