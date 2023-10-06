CREATE   PROCEDURE [dbo].[b_delpack_from_file]
(
	@filedbf_id	 INT
	,@kol_del_pack INT = 0  OUTPUT 
)
AS
/*
	удаляем пачки по заданному реестру в текущем периоде

	delete @kol_del_pack INT
	exec b_delpack_from_file @filedbf_id=0, @kol_del_pack=@kol_del_pack OUT
	select @kol_del_pack

*/

SET NOCOUNT ON


SET @kol_del_pack=0

IF EXISTS (SELECT
				1
			FROM dbo.Bank_Dbf AS bd
			LEFT JOIN dbo.Paydoc_packs AS pp
				ON bd.pack_id = pp.id
			LEFT JOIN dbo.Occupation_Types ot
				ON pp.tip_id = ot.id
			WHERE 
				filedbf_id = @filedbf_id
				AND bd.pack_id IS NOT NULL
				AND pp.fin_id < ot.fin_id
			)
BEGIN
	RAISERROR ('Есть сформированные пачки в истории!', 16, 1)
	RETURN 1
END

-- удаляем пачки если есть 
DECLARE @pack_id1   INT
	   ,@forwarded1 BIT
	   ,@success	BIT

DECLARE cur CURSOR LOCAL FOR
	SELECT DISTINCT
		bd.pack_id
	   ,pp.forwarded
	FROM dbo.Bank_Dbf bd
		JOIN dbo.Paydoc_packs pp ON 
			bd.pack_id = pp.id
	WHERE 
		filedbf_id = @filedbf_id
		AND bd.pack_id IS NOT NULL

OPEN cur;
FETCH NEXT FROM cur INTO @pack_id1, @forwarded1;
WHILE @@fetch_status = 0
BEGIN

  	IF @forwarded1 = 1
			-- сначала возвращаем пачку
			EXEC adm_packs_out @pack_id1 = @pack_id1
							  ,@debug = 0
							  ,@ras1 = 0

	EXECUTE dbo.k_paydoc_delete  @id1=@pack_id1, @success=@success OUTPUT

	IF @success=1
		SET @kol_del_pack=@kol_del_pack+1

	FETCH NEXT FROM cur INTO @pack_id1, @forwarded1;
END
CLOSE cur;
DEALLOCATE cur;
go

