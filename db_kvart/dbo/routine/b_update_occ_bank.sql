-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[b_update_occ_bank]
(
    @id      INT,
    @sch_lic INT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @occ INT      = NULL,
            @kol SMALLINT = 0

	SELECT @occ = dbo.Fun_GetOccFromSchet(@sch_lic)

	IF @occ IS NOT NULL
	BEGIN
		UPDATE b
		SET service_id = dbo.Fun_GetService_idFromSchet(@sch_lic)
		  , occ = @occ
		  , sup_id = dbo.Fun_GetSUPFromSchetl(@sch_lic)
		  , dog_int = dbo.Fun_GetDOGFromSchetl(@sch_lic)
		FROM dbo.BANK_DBF AS b
		WHERE b.id = @id

		SELECT @kol = @@rowcount
	END

	SELECT kol=@kol

END
go

