CREATE   PROCEDURE [dbo].[adm_subsidia_del]
AS
	--
	-- Удаление субсидий по сроку
	-- (удаляються за предыдущий фин период и старше)
	--
	SET NOCOUNT ON

	DECLARE @fin_id1	 INT
		   ,@start_date1 SMALLDATETIME
		   ,@end_date1	 SMALLDATETIME


	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	SELECT
		@start_date1 = start_date
	   ,@end_date1 = end_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_id1


	DECLARE @t TABLE
		(
			fin_id SMALLINT
		   ,occ	   INT
		)
	INSERT INTO @t
	(fin_id
	,occ)
		SELECT
			fin_id
		   ,occ
		FROM dbo.COMPENSAC_ALL
		WHERE DateEnd <= @start_date1

	BEGIN TRAN

		DELETE cs
			FROM dbo.COMP_SERV_ALL AS cs
			JOIN @t AS t
				ON cs.fin_id = t.fin_id
				AND cs.occ = t.occ

		DELETE c
			FROM dbo.COMPENSAC_ALL AS c
			JOIN @t AS t
				ON c.fin_id = t.fin_id
				AND c.occ = t.occ


		COMMIT TRAN
go

