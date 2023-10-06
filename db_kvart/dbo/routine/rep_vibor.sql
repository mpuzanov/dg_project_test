-- =============================================
-- Author:		Пузанов
-- Create date: 17.10.18
-- Description:	Список выборок(для Картотеки)
-- =============================================
CREATE PROCEDURE [dbo].[rep_vibor]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		id = 1
	   ,name = 'Все услуги'
	UNION ALL
	SELECT
		id = 2
	   ,name = 'По ед.квитанции'
	UNION ALL
	SELECT
		id = 3
	   ,name = 'По поставщику'

END
go

