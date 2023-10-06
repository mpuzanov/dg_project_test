CREATE   PROCEDURE  [dbo].[k_foto_users]
(  @users_id1 int
)
AS
/*
  Просмотр фотографии пользователя системы
*/
SET NOCOUNT ON

SELECT foto FROM dbo.USERS WHERE id=@users_id1
go

