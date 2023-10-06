-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Взять режимы с другого лицевого счета
-- =============================================
CREATE     PROCEDURE [dbo].[k_modeset_from_occ] 
(
@occ1 int
,@occ_from int
,@debug bit = 0
)
AS
/*
EXEC k_modeset_from_occ @occ1=31002, @occ_from=31001, @debug=1
EXEC k_modeset_from_occ @occ1=166015, @occ_from=166001, @debug=1
*/
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 From dbo.Occupations WHERE occ=@occ_from)
	BEGIN
		RAISERROR('Лицевой счет %d не найден', 16, 1, @occ_from)
		RETURN
	END

	DECLARE @fin_current SMALLINT
	SELECT @fin_current=dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	CREATE TABLE #Log
    (MergeAction nvarchar(10) COLLATE database_default,
	 occ int,  
     service_id varchar(10) COLLATE database_default,  
     sup_id int,  
     mode_id int,  
     source_id int
    ); 

	MERGE dbo.Consmodes_list AS target  
		USING (SELECT occ,service_id,sup_id,mode_id,source_id 
		FROM dbo.Consmodes_list WHERE occ=@occ_from) as source
		ON (target.service_id=source.service_id
		AND target.sup_id=source.sup_id)
		AND target.occ=@occ1
	WHEN MATCHED AND (target.mode_id <> source.mode_id OR target.source_id <> source.source_id)
	THEN  
		UPDATE SET mode_id = source.mode_id, source_id=source.source_id  
	WHEN NOT MATCHED THEN  
		INSERT (occ,service_id,sup_id,mode_id,source_id,fin_id)
		VALUES (@occ1,source.service_id,source.sup_id,source.mode_id,source.source_id,@fin_current)  
   OUTPUT $action as MergeAction, 
   CASE $action 
        WHEN 'DELETE' THEN deleted.occ 
        ELSE inserted.occ END AS occ,
    CASE $action 
        WHEN 'DELETE' THEN deleted.service_id 
        ELSE inserted.service_id END AS service_id,
    CASE $action 
        WHEN 'DELETE' THEN deleted.sup_id 
        ELSE inserted.sup_id END AS sup_id,
    CASE $action 
        WHEN 'DELETE' THEN deleted.mode_id 
        ELSE inserted.mode_id END AS mode_id,
    CASE $action 
        WHEN 'DELETE' THEN deleted.source_id 
        ELSE inserted.source_id END AS source_id
   -- deleted.occ,deleted.service_id,deleted.sup_id,deleted.mode_id,deleted.source_id, 
   -- inserted.occ,inserted.service_id,inserted.sup_id,inserted.mode_id,inserted.source_id 
	INTO #Log;  
	;

	IF @debug=1 SELECT * FROM #Log

END
go

