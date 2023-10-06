-- =============================================
-- Author:		Пузанов
-- Create date: 11.02.2011
-- Description:	Возврат разового
-- =============================================
CREATE     PROCEDURE [dbo].[ka_vozvrat_add]
(
	@id			INT
	,@doc_new		VARCHAR(100)	= NULL
	,@rows_add	INT	= 0 OUTPUT
-- если >0 то разовые добавили
)
AS
BEGIN
	SET NOCOUNT ON;


	DECLARE @user_edit1  SMALLINT
	SELECT
		@user_edit1 = dbo.Fun_GetCurrentUserId()

	INSERT INTO dbo.ADDED_PAYMENTS
	(	occ
		,service_id
		,sup_id
		,add_type
		,value
		,doc
		,doc_no
		,comments
		,user_edit
		,fin_id)
		SELECT
			ap.occ
			,service_id
			,sup_id
			,add_type
			,-1 * ap.value
			,COALESCE(@doc_new, ap.doc)
			,RTRIM(SUBSTRING(ap.doc_no, 1, 8)) + '/В'
			,comments
			,@user_edit1
			,dbo.Fun_GetFinCurrent(NULL, NULL, NULL, ap.occ)
		FROM [dbo].[ADDED_PAYMENTS_HISTORY] AS ap
		WHERE ap.id = @id
	--occ = @occ
	--AND fin_id = @fin_id
	--AND service_id = @service_id
	--AND add_type = @add_type
	--AND value = @value
	--AND COALESCE(doc, '') = COALESCE(@doc, '') --doc=coalesce(@doc,doc)

	SELECT
		@rows_add = @@rowcount

END
go

