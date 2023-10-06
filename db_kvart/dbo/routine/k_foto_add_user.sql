CREATE   PROCEDURE [dbo].[k_foto_add_user]
( @user_id1 INT,
  @foto1 IMAGE
)
AS
/*
  Добавляем или изменяем фотографию человека в базе 
*/
SET NOCOUNT ON
 
UPDATE dbo.USERS SET foto=@foto1 WHERE id=@user_id1
go

