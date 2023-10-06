-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	
-- =============================================
CREATE     PROCEDURE [dbo].[adm_build_arenda_select]
(
	@build_id1		INT
	,@service_id1	VARCHAR(10)	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		b.*
	FROM dbo.Build_arenda AS b
	WHERE b.build_id = @build_id1
	AND (service_id = @service_id1
	OR @service_id1 IS NULL)
	ORDER BY b.fin_id DESC

END
go

