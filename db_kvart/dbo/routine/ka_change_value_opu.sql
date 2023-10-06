-- =============================================
-- Author:		Пузанов
-- Create date: 21.04.2022
-- Description:	Изменение суммы или кол-ва у ОБЩЕДОМОВЫХ расчётов
-- =============================================
CREATE           PROCEDURE [dbo].[ka_change_value_opu]
	 @fin_id1 SMALLINT
	, @occ1 INT
	, @service_id1 VARCHAR(10)
	, @value DECIMAL(9, 2) = NULL -- новая сумма разового
	, @kol_new DECIMAL(9, 4) = NULL -- новое кол-во разового
	, @ZapUpdate INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	IF @value IS NULL
		AND @kol_new IS NULL
		RETURN


	UPDATE pcb 
	SET pcb.Value = COALESCE(@value, pcb.Value)
	  , pcb.kol = COALESCE(@kol_new, pcb.kol)
	  , pcb.user_login = suser_sname()
	  , pcb.data = current_timestamp
	FROM dbo.Paym_occ_build AS pcb
		JOIN dbo.Occupations as o 
			ON pcb.occ=o.Occ 
			AND pcb.fin_id=o.fin_id  -- изменять можно только в текущем периоде
	WHERE pcb.fin_id = @fin_id1
	AND pcb.occ=@occ1
	AND pcb.service_id=@service_id1
	SELECT @ZapUpdate = @@rowcount

END
go

