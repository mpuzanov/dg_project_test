CREATE   PROCEDURE [dbo].[k_ShowPerson]
AS
/*	
	  Показываем список статусов регистрации
*/	
SET NOCOUNT ON

SELECT
	*
FROM dbo.PERSON_STATUSES
ORDER BY id_no, name
go

