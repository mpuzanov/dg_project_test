-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	
-- =============================================
CREATE     PROCEDURE [dbo].[adm_build_value_select]
(
	  @build_id1 INT
	, @service_id1 VARCHAR(10) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT b.fin_id
		 , b.build_id
		 , b.service_id
		 , b.value_source
	FROM Build_source_value AS b
	WHERE b.build_id = @build_id1
		AND (@service_id1 is null OR service_id = @service_id1)
	ORDER BY b.fin_id DESC;

END
go

