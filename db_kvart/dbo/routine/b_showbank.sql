CREATE   PROCEDURE [dbo].[b_showbank]
(
	@banks BIT = 1  -- только банки
)
AS
	/*
	
	Показываем список банков или организаций по взаимозачетам

	автор: Пузанов 

	дата последней модификации:  03.10.05
	автор изменений:  Кривобоков А.В.
	в селекте добавил po_id=po.id для различных сортировок в Dbank
	
	дата последней модификации:  21.09.09
	сделал все в одном запросе
	
	*/

	SET NOCOUNT ON

	DECLARE @Fin_current SMALLINT
	SELECT
		@Fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	SELECT
		b.id
	   ,po.id AS po_id
	   ,b.short_name
	   ,CONCAT(po.ext , '   ') AS ext
	   ,CONCAT(b.short_name , ' (' , po.ext , ')') AS bank
	FROM dbo.bank AS b 
	JOIN dbo.View_PAYCOLL_ORGS AS po ON 
		b.id = po.bank
	WHERE 
		(@banks IS NULL OR b.is_bank = @banks)
		AND po.fin_id = @Fin_current
go

