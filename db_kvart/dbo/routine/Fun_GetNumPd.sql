CREATE   FUNCTION [dbo].[Fun_GetNumPd]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
RETURNS VARCHAR(20)
AS
BEGIN
	/*
	
	Выдаем номер платёжного документа
	
	select dbo.Fun_GetNumPd(45321,170, null)     -- 45321_20160301
	select dbo.Fun_GetNumPd(85607809,169, null)  -- 85607809_20160201
	*/

	IF COALESCE(@sup_id,0)>0
		SELECT
			@occ = os.occ_sup
		FROM Occ_Suppliers os
		WHERE os.occ = @occ
		AND os.fin_id = @fin_id
		AND os.sup_id = @sup_id

	RETURN (SELECT
			CONCAT(@occ, '_', CONVERT(VARCHAR(8), start_date, 112))
		FROM dbo.Global_values gv
		WHERE gv.fin_id = @fin_id)
	

END
go

