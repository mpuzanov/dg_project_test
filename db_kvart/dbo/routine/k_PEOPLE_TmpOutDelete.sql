CREATE   PROC [dbo].[k_PEOPLE_TmpOutDelete]
    @occ      INT,
    @owner_id INT,
    @data1    SMALLDATETIME,
    @del_add  BIT = 0  -- удалить так же перерасчёты по этому гражданину
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @del_add IS NULL
		SET @del_add = 0

	BEGIN TRAN

	IF @del_add = 1
		DELETE ap
		FROM
			dbo.ADDED_PAYMENTS AS ap
			JOIN [dbo].[PEOPLE_TmpOut] AS pt
				ON pt.occ = ap.occ AND ap.dsc_owner_id = pt.owner_id AND ap.fin_id = pt.fin_id
		WHERE
			ap.occ = @occ AND
			ap.add_type = 3 AND
			ap.doc_no = '888' AND
			pt.owner_id = @owner_id AND
			pt.data1 = @data1

	DELETE
	FROM
		[dbo].[PEOPLE_TmpOut]
	WHERE
		[occ] = @occ AND
		[owner_id] = @owner_id AND
		[data1] = @data1

	COMMIT
go

