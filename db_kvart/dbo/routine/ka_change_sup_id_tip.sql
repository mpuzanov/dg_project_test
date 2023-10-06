-- =============================================
-- Author:		Пузанов
-- Create date: 27.09.2016
-- Description:	Изменение поставщика у перерасчёта с выбором типа фонда или дома
-- =============================================
CREATE         PROCEDURE [dbo].[ka_change_sup_id_tip]
	@tip_id			SMALLINT
	,@build_id		INT	= NULL -- код дома
	,@service_id	VARCHAR(10) -- код услуги
	,@sup_id_old	INT	-- код старого поставщика
	,@sup_id_new	INT -- код нового поставщика
	,@ZapUpdate		INT	= 0 OUTPUT
AS
BEGIN
/*
DECLARE @RC int
DECLARE @tip_id smallint
DECLARE @build_id int
DECLARE @service_id VARCHAR(10)
DECLARE @sup_id_old int
DECLARE @sup_id_new int
DECLARE @ZapUpdate int

-- TODO: задайте здесь значения параметров.

EXECUTE @RC = [dbo].[ka_change_sup_id_tip] 
   @tip_id
  ,@build_id
  ,@service_id
  ,@sup_id_old
  ,@sup_id_new
  ,@ZapUpdate OUTPUT
GO

*/
	SET NOCOUNT ON;

	DECLARE @var1 INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT
			ap.id
		FROM dbo.Added_Payments ap
		JOIN dbo.Occupations o
			ON ap.occ = o.occ
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		WHERE 
			o.tip_id = @tip_id
			AND (f.bldn_id = @build_id OR @build_id IS NULL)
			AND ap.service_id = @service_id
			AND ap.sup_id = @sup_id_old

	OPEN cur
	FETCH NEXT FROM cur INTO @var1
	WHILE @@fetch_status = 0
	BEGIN

		UPDATE ap 
		SET ap.sup_id = @sup_id_new
		FROM dbo.Added_Payments AS ap
		WHERE ap.id = @var1
		SELECT
			@ZapUpdate = @ZapUpdate + @@rowcount

		FETCH NEXT FROM cur INTO @var1
	END
	CLOSE cur;
	DEALLOCATE cur;

END
go

