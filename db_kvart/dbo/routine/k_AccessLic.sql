CREATE   PROCEDURE [dbo].[k_AccessLic]
(
	@occ1 INT
)
AS
	/*
		Проверка доступа к заданному лицевому для текщего доступа
	*/
	IF dbo.Fun_AccessJeuLic(@occ1) = 0
		RAISERROR ('Доступ к этому лицевому запрещен!', 16, 10)
go

