-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE     PROCEDURE [dbo].[ws_suppliers]
(
@service_id VARCHAR(10) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

    IF @service_id = '' SET @service_id=NULL
	SELECT id=0, service_id=@service_id, name='Не заполнено'
	UNION ALL
 	SELECT id, service_id, name=RTRIM(name) FROM View_SUPPLIERS 
    WHERE service_id=CASE
          WHEN @service_id IS NULL THEN service_id
          ELSE @service_id
    END

END
go

