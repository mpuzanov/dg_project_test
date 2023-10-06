CREATE   FUNCTION [dbo].[Fun_GetNumPdSup] (@occ INT
, @fin_id SMALLINT
, @sup_id INT = NULL)
RETURNS VARCHAR(20)
AS
BEGIN
  /*
	
	Выдаем номер платёжного документа
	
	select dbo.Fun_GetNumPdSup(680004696,169,323)
	*/

  DECLARE @num_pd VARCHAR(20)
  IF @sup_id > 0
  BEGIN
    SELECT
      @num_pd = dbo.Fun_GetNumPd(os.occ_sup, os.fin_id, NULL)
    FROM OCC_SUPPLIERS os
    WHERE os.occ = @occ
    AND os.fin_id = @fin_id
    AND os.sup_id = @sup_id
  END
  ELSE
    SELECT
      @num_pd = dbo.Fun_GetNumPd(@occ, @fin_id, NULL)

  RETURN @num_pd


END
go

