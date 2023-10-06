CREATE   FUNCTION [dbo].[Fun_GetNumUV]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
RETURNS VARCHAR(16)
AS
BEGIN
	/*
	
	Функция формирования уникального начисления
	
	select dbo.Fun_GetNumUV(45321,170,null)    -- 0000045321160301	
	select dbo.Fun_GetNumUV(85607809,169,null) -- 0085607809160201
	*/

	IF @sup_id > 0
		SELECT
			@occ = os.occ_sup
		FROM dbo.Occ_Suppliers os 
		WHERE os.occ = @occ
			AND os.fin_id = @fin_id
			AND os.sup_id = @sup_id

	RETURN (SELECT
			CONCAT(RIGHT('0000000000'+CAST(@occ AS VARCHAR), 10), CONVERT(VARCHAR(6), start_date, 12)) --'%010i%s%02i01'
		FROM dbo.Global_values gv
		WHERE gv.fin_id = @fin_id)
	

END
go

