-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2011
-- Description:	Получаем строку тарифов
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetTarifStrServ]
(
	@fin_id1		SMALLINT
	,@tipe_id		SMALLINT	= NULL
	,@service_id	VARCHAR(10)
	,@mode_id		INT
)
RETURNS VARCHAR(50)
/*
Возврат строки тарифов

select [dbo].[Fun_GetTarifStrServ](159,28,'ремт',16037)
select [dbo].[Fun_GetTarifStrServ](159,null,'площ',1001)
select [dbo].[Fun_GetTarifStrServ](160,130,'площ',1002)
*/
AS
BEGIN

	RETURN
	COALESCE((SELECT
			STUFF((SELECT
					',' + LTRIM(STR(r.value, 8, 2))
				FROM dbo.RATES AS r 
				WHERE finperiod = @fin_id1
				AND (r.tipe_id = @tipe_id
				OR @tipe_id IS NULL)
				AND r.service_id = @service_id
				AND r.mode_id = @mode_id
				AND r.value > 0
				GROUP BY r.value
				FOR XML PATH (''))
			, 1, 1, ''))
	, '')
END
go

