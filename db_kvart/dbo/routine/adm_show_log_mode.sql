-- =============================================
-- Author:		<Author,,Name>
-- Create date: 04.07.16
-- Description:	Журнал изменения режимов по дому
-- =============================================
CREATE   PROCEDURE [dbo].[adm_show_log_mode]
(
@row_show INT = 1000
)
AS
BEGIN
	SET NOCOUNT ON;
	IF @row_show IS NULL
		SET @row_show=1000

	SELECT TOP (@row_show)
		--op.[id]
		'Дата'=[done]
		,'Дом'=vbl.adres
		,'Пользователь' = dbo.Fun_GetFIOUser([user_id])
		,'Услуга'=s.[name]
		,[id_old]
		,[id_new]
		,'Комментарий'=[comments]
		,'Приложение'=[app]
		,mode =
			CASE is_mode
				WHEN 1 THEN 'Режим'
				WHEN 2 THEN 'Поставщик'
				ELSE ''
			END
	--delete
	FROM [dbo].[OP_LOG_MODE] AS op
	JOIN View_BUILDINGS_LITE vbl
		ON op.build_id = vbl.id
	JOIN dbo.Services as s
		ON op.service_id=s.id
	ORDER BY op.done DESC
END
go

