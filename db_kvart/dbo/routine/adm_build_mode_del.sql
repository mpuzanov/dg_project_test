-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_build_mode_del]
(
@build_id INT
,@is_source_del BIT = NULL -- 0 - убираем режимы, 1 - поставщиков
)
AS
/*
убираем режимы потребления или поставщиков в доме
*/
BEGIN
	SET NOCOUNT ON;

	SET @is_source_del=COALESCE(@is_source_del, 0)
	
	BEGIN TRAN
	
		-- убираем с лицевых
		UPDATE cl
			SET mode_id = 
			CASE
				WHEN @is_source_del=cast(1 as bit) THEN mode_id
				WHEN mode_id % 1000 = 0 THEN mode_id
				ELSE s.service_no * 1000
			END
			,source_id = 
			CASE
				WHEN @is_source_del=cast(0 as bit) THEN source_id
				WHEN source_id % 1000 = 0 THEN source_id
				ELSE s.service_no * 1000
			END
		FROM dbo.Consmodes_list as cl
			JOIN dbo.Occupations as o ON o.occ=cl.occ
			JOIN dbo.Flats as f ON f.id=o.flat_id
			JOIN dbo.Services as s ON s.id=cl.service_id	
		WHERE f.bldn_id=@build_id
		
		-- убираем с выбора дома
		IF @is_source_del=cast(0 as bit)
			DELETE t
			FROM dbo.Build_mode as t
				JOIN dbo.Services as s ON s.id=t.service_id
			WHERE t.build_id=@build_id
				AND (mode_id % 1000 <> 0)
		ELSE
			DELETE t
			FROM dbo.Build_source as t
				JOIN dbo.Services as s ON s.id=t.service_id
			WHERE t.build_id=@build_id
				AND (source_id % 1000 <> 0)
	
	COMMIT TRAN
END
go

