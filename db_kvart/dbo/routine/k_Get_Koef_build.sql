CREATE   PROCEDURE [dbo].[k_Get_Koef_build] 
(
  @build_id1 INT, 
  @service_id1 VARCHAR(10)
)
AS
  /*
  	Возвращаем результирующий коэффициент по дому
  */
  SET NOCOUNT ON

  DECLARE @SumKoef DECIMAL(9, 6)

  SELECT
    @SumKoef = value
  FROM Koef_build AS ko
  WHERE ko.build_id = @build_id1
	AND ko.service_id = @service_id1

  SELECT
    ROUND(COALESCE(@SumKoef,2), 4) AS SumKoef
go

