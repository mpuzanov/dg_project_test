/*
-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
*/
CREATE     PROCEDURE [dbo].[ws_streets] 
(
@is_json BIT = 0
)
/*
 exec ws_streets 
 exec ws_streets 1
*/
AS
BEGIN
	SET NOCOUNT ON;

	IF @is_json IS NULL SET @is_json=0

	IF @is_json=0
		SELECT name
		FROM dbo.STREETS s
		ORDER BY name
	ELSE
		SELECT name
		FROM dbo.Streets s
		FOR JSON AUTO , ROOT('streets')
		--FOR JSON PATH, ROOT('streets')
END
go

