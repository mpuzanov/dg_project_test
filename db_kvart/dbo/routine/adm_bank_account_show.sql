-- =============================================
-- Author:		Пузанов
-- Create date: 09.02.2010
-- Description:	Список банковских счетов по заданной организации
-- =============================================
CREATE       PROCEDURE [dbo].[adm_bank_account_show]
(
@tip1 SMALLINT = NULL -- 1-Тип фонда, 3-Поставщик, 5-Дом, 6-Договор
,@onlyVisible BIT = NULL -- Признак запроса для выбора
)
AS
/*
exec adm_bank_account_show @tip1=6
exec adm_bank_account_show @tip1=1, @onlyVisible=1 
exec adm_bank_account_show @onlyVisible=1
*/
BEGIN
	SET NOCOUNT ON;

	SELECT  ao.*,
	        CASE ao.tip
				WHEN 1 THEN 'Тип фонда'
				WHEN 2 THEN 'Участок'
				WHEN 3 THEN 'Поставщик'
				WHEN 4 THEN 'Район'
				WHEN 5 THEN 'Дом'
				WHEN 6 THEN 'Договор'
				WHEN 7 THEN 'Лицевой'
				ELSE ''
	        END as name_org
	FROM  dbo.Account_org AS ao
	WHERE (ao.tip=@tip1 OR @tip1 is NULL)
	AND (ao.visible = @onlyVisible OR @onlyVisible is NULL)
	ORDER BY ao.visible DESC, ao.id DESC

END
go

