-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Платежи
-- =============================================
CREATE       PROCEDURE [dbo].[rep_ivc_pay]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*
По Платежам

rep_ivc_pay @fin_id=176,@tip_id=28,@build_id=1031,@format='xml'
rep_ivc_pay @fin_id=232,@tip_id=1,@build_id=null,@sup_id=345
rep_ivc_pay @fin_id=232,@tip_id=1,@build_id=null,@sup_id=null

*/
BEGIN
	SET NOCOUNT ON;


	EXEC rep_ivc_pay_new @fin_id = @fin_id
					   , @tip_id = @tip_id
					   , @build_id = @build_id
					   , @sup_id = @sup_id
					   , @is_only_paym = @is_only_paym
					   , @format = @format
	RETURN

END
go

