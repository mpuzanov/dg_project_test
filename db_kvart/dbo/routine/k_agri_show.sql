-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[k_agri_show]
(
@fin_id SMALLINT,
@occ INT
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT AO.*, name, kol_norma
	FROM dbo.AGRICULTURE_OCC AO
	JOIN dbo.AGRICULTURE_VID AV ON AO.ani_vid=AV.id
	WHERE fin_id=@fin_id
	AND occ=@occ
	
END
go

