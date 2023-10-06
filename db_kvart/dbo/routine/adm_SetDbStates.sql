CREATE   PROCEDURE [dbo].[adm_SetDbStates]
(
	@dbstate_id1 VARCHAR(10)
)
AS
/*	
	 Устанавливает состояние базы
*/	
	SET NOCOUNT ON

	-- Обнуляем состояние
	UPDATE Db_states
	SET is_current = 0
	WHERE is_current = 1;

	-- Устанавливем состояние
	UPDATE Db_states
	SET is_current = 1
	WHERE dbstate_id = @dbstate_id1;

	EXEC adm_permission;
go

