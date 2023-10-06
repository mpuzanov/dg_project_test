-- =============================================
-- Author:		Пузанов
-- Create date: 24.05.2010
-- Description:	Получаем последнию версию(код) клиентской программы
-- =============================================
CREATE PROCEDURE [dbo].[k_GetLastVersionProg]
(
	@program_name VARCHAR(20)
)
AS
/*
k_GetLastVersionProg 'Отчёты.exe'
k_GetLastVersionProg ''
*/
BEGIN

	SET NOCOUNT ON;

	SELECT TOP 1
		VersiaInt = coalesce(VersiaInt, 0)
		,VersiaStr = coalesce(VersiaStr, '')
	FROM dbo.version 
	WHERE [program_name] = @program_name

END
go

