-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[ka_opu_del]
(
    @fin_id     SMALLINT,
    @occ        INT,
    @service_id VARCHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	
	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	-- удаляем только в текущем фин.периоде
	IF EXISTS (SELECT TOP 1 V.occ
			   FROM
				   dbo.VOCC V
			   WHERE V.Occ=@occ
			   AND V.fin_id = @fin_id)
		DELETE
		FROM
			[dbo].[PAYM_OCC_BUILD]
		WHERE
			fin_id = @fin_id AND
			occ = @occ AND
			service_id = @service_id
	ELSE
	BEGIN
		RAISERROR('Удалять можно только в текущем фин.периоде!',16,1)
		RETURN
	END

END
go

