CREATE   PROCEDURE [dbo].[k_pasport_show]
(
	@owner_id1 INT
)
AS
	--
	--
	--
	SET NOCOUNT ON

	SELECT
		CASE
			WHEN active = 1 THEN 'Да'
			ELSE 'Нет'
		END AS ActiveStr
		,t1.id
		,t1.owner_id
		,t1.active
		,t1.DOCTYPE_ID
		,t1.PASSSER_NO
		,t1.DOC_NO
		,t1.ISSUED
		,t1.DOCORG
		,t2.name
		,t1.date_edit
		,dbo.Fun_GetFIOUser(t1.user_edit) AS user_name
		,t1.kod_pvs
	FROM dbo.IDDOC AS t1 
	JOIN dbo.IDDOC_TYPES AS t2 
		ON t1.DOCTYPE_ID = t2.id
	WHERE t1.owner_id = @owner_id1
	ORDER BY t1.active DESC, t1.ISSUED DESC
go

