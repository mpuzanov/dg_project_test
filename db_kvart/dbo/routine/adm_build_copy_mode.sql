-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Копирование режимов потребления и поставщиков с другого дома
-- =============================================
CREATE       PROCEDURE [dbo].[adm_build_copy_mode]
(
	  @build_id_source INT
	, @build_id_target INT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- копируем режимы с дома  Build_mode
	MERGE Build_mode AS target USING (
		SELECT build_id
			 , service_id
			 , mode_id
		FROM Build_mode
		WHERE build_id = @build_id_source
	) AS source
	ON (target.build_id = @build_id_target
		AND target.service_id = source.service_id
		AND target.mode_id = source.mode_id)
	WHEN NOT MATCHED
		THEN INSERT
				(build_id
			   , service_id
			   , mode_id)
				VALUES (@build_id_target
					  , source.service_id
					  , source.mode_id);

	-- копируем поставщиков с дома Build_source
	MERGE Build_source AS target USING (
		SELECT build_id
			 , service_id
			 , source_id
		FROM Build_source
		WHERE build_id = @build_id_source
	) AS source
	ON (target.build_id = @build_id_target
		AND target.service_id = source.service_id
		AND target.source_id = source.source_id)
	WHEN NOT MATCHED
		THEN INSERT
				(build_id
			   , service_id
			   , source_id)
				VALUES (@build_id_target
					  , source.service_id
					  , source.source_id);


	-- добавляем режимы и поставщиков на лицевые (добаляем "Нет")
	INSERT INTO dbo.Consmodes_list
		(occ
	   , service_id
	   , sup_id
	   , source_id
	   , mode_id
	   , subsid_only
	   , is_counter
	   , account_one
	   , fin_id)
	SELECT o.occ
		 , s.id
		 , 0
		 , s.service_no * 1000
		 , s.service_no * 1000
		 , 0
		 , 0
		 , 0
		 , b.fin_current
	FROM dbo.Occupations o
		JOIN dbo.Flats f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id=b.id
		JOIN dbo.Build_source bs 
			ON f.bldn_id = bs.build_id
		JOIN dbo.Services s 
			ON bs.service_id = s.id
	WHERE f.bldn_id = @build_id_target
		AND bs.source_id % 1000 = 0
		AND NOT EXISTS (
			SELECT *
			FROM dbo.Consmodes_list AS cl
				JOIN dbo.View_occ_all_lite voal ON cl.fin_id = voal.fin_id
					AND cl.occ = voal.occ
			WHERE cl.occ = o.occ
				AND cl.service_id = s.id
				AND cl.sup_id = 0
				AND voal.build_id = @build_id_target
		)
END
go

