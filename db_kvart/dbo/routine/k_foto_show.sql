CREATE   PROCEDURE [dbo].[k_foto_show](@owner_id1 int
)
AS
/*
  Показываем фотографию человека в базе 
*/
SET NOCOUNT ON

SELECT t.owner_id, t.foto
FROM dbo.People_image as t 
WHERE t.owner_id = @owner_id1
go

