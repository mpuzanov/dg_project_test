CREATE   PROCEDURE [dbo].[k_show_pasport]
(
    @owner_id1 INT
)
AS
	--
	--
	--
	SET NOCOUNT ON

	SELECT t1.id
		 , t1.owner_id
		 , t1.active
		 , t1.DOCTYPE_ID
		 , t1.DOC_NO
		 , t1.PASSSER_NO
		 , t1.ISSUED
		 , t1.DOCORG
		 , t2.name
	FROM
		dbo.IDDOC AS t1 , dbo.IDDOC_TYPES AS t2 
	WHERE
		t1.owner_id = @owner_id1
		AND t1.doctype_id = t2.id
go

