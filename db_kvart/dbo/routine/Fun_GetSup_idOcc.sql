-- =============================================
-- Author:		Пузанов
-- Create date: 18.09.2016
-- Description:	Возвращаем код поставщика на Л/сч по услуге
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetSup_idOcc]
(
	@occ1			INT
	,@service_id	VARCHAR(10)
)
RETURNS INT
AS
BEGIN

	RETURN COALESCE(

	(SELECT TOP (1)
		cl.sup_id
	FROM CONSMODES_LIST cl
	WHERE cl.occ = @occ1
	AND cl.service_id = @service_id
	AND (cl.source_id % 1000 != 0)

	), 0)

END
go

