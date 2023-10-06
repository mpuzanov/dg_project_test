CREATE   PROCEDURE [dbo].[adm_proverka_modes2]
AS
/*
Находим режимы которые есть на лицевых и нет на доме
и добавляем их в дома
		
	execute adm_proverka_modes2
*/
	SET NOCOUNT ON


	DECLARE	@build_id1		INT
			,@service_id1	VARCHAR(10)
			,@mode_id1		INT
			,@source_id		INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT DISTINCT
			cl.service_id
			,cl.mode_id
			,vo.build_id
		FROM dbo.Consmodes_list cl 
		JOIN dbo.VOcc vo
			ON cl.occ = vo.occ
		JOIN dbo.Cons_modes cm 
			ON cl.service_id = cm.service_id
			AND cl.mode_id = cm.id
		LEFT JOIN dbo.Build_mode bm 
			ON cm.id = bm.mode_id
			AND cm.service_id = bm.service_id
			AND vo.build_id = bm.build_id
		WHERE bm.mode_id IS NULL

	OPEN cur

	FETCH NEXT FROM cur INTO @service_id1, @mode_id1, @build_id1

	WHILE @@fetch_status = 0
	BEGIN

		INSERT
		INTO BUILD_MODE
		(	build_id
			,service_id
			,mode_id)
		VALUES (@build_id1, @service_id1, @mode_id1)

		FETCH NEXT FROM cur INTO @service_id1, @mode_id1, @build_id1
	END

	CLOSE cur
	DEALLOCATE cur


	DECLARE cur CURSOR LOCAL FOR
		SELECT DISTINCT
			cl.service_id
			,cl.source_id
			,vo.build_id
		FROM dbo.Consmodes_list cl 
		JOIN dbo.VOcc vo
			ON cl.occ = vo.occ
		JOIN dbo.Suppliers cm 
			ON cl.service_id = cm.service_id
			AND cl.source_id = cm.id
		LEFT JOIN dbo.Build_source bs 
			ON cm.id = bs.source_id
			AND cm.service_id = bs.service_id
			AND vo.build_id = bs.build_id
		WHERE bs.source_id IS NULL

	OPEN cur

	FETCH NEXT FROM cur INTO @service_id1, @source_id, @build_id1

	WHILE @@fetch_status = 0
	BEGIN

		INSERT
		INTO BUILD_SOURCE
		(	build_id
			,service_id
			,source_id)
		VALUES (@build_id1, @service_id1, @source_id)

		FETCH NEXT FROM cur INTO @service_id1, @source_id, @build_id1
	END
go

