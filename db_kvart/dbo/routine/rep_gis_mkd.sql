-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_gis_mkd]
(
	  @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @only_new BIT = 0
	, @is_flat BIT = NULL
)
AS
/*
exec rep_gis_mkd 28,null,323
exec rep_gis_mkd 28,1057,323
exec rep_gis_mkd 28,1077,323,1
exec rep_gis_mkd 109,4102,null,1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())


	IF (@DB_NAME <> 'NAIM'
		AND @tip_id IS NULL)
		SET @tip_id = -1

	--IF (@build_id IS NULL) --AND (@DB_NAME <> 'NAIM')
	--	AND system_user <> 'sa'
	--BEGIN
	--	RAISERROR ('Данные формируются только по дому!', 16, 1);
	--	RETURN
	--END

	IF @only_new IS NULL
		SET @only_new = 0

	SELECT *
	FROM (
		SELECT b.adres
			 , f.nom_kvr
			 , b.kod_fias
			 , COALESCE((
				   SELECT TOP (1) f.id_nom_gis
				   FROM dbo.Occupations o1
					   JOIN dbo.Flats f1 ON o1.flat_id = f1.id
				   WHERE o1.flat_id = f.id
					   AND o1.status_id <> 'закр'
					   AND o1.TOTAL_SQ > 0
			   ), '') AS id_nom_gis
			 , b.oktmo AS oktmo
			 , CASE
				   WHEN b.old = 1 THEN 'Ветхий'
				   ELSE 'Исправный'
			   END AS old
			 , 'Эксплуатация' AS stage  -- стадия жизненного цикла (Эксплуатация,Реконструкция,Капитальный ремонт с отселением,Капитальный ремонт без отселения)
			 , b.build_total_sq + COALESCE(b.arenda_sq, 0) + COALESCE(b.opu_sq, 0) AS build_total_sq
			 , b.TOTAL_SQ AS TOTAL_SQ
			 , CASE
				   WHEN (b.godp > 1600) THEN b.godp
				   ELSE 0
			   END AS godp
			 , COALESCE(b.levels, 0) AS levels
			 , COALESCE(b.levels_underground, 0) AS levels_underground
			 , COALESCE(b.levels_min, 0) AS levels_min
			 , COALESCE(t.TOTAL_SQ, 0) AS flat_total_sq
			 , COALESCE(t.living_sq, 0) AS flat_living_sq
			 , CASE WHEN(f.rooms>0) THEN f.rooms ELSE COALESCE(t.kol_rooms, 0) END AS flat_kol_rooms
			 , COALESCE(t.kol_people, 0) AS flat_kol_people
			 , t.kol_occ
			 , COALESCE((
				   SELECT TOP (1) o1.PROPTYPE_ID
				   FROM dbo.Occupations o1 
				   WHERE o1.flat_id = f.id
					   AND o1.status_id <> 'закр'
					   AND o1.TOTAL_SQ > 0
			   ), '') AS PROPTYPE_ID
			 , CASE
				   WHEN b.kultura = 1 THEN 'Да'
				   ELSE 'Нет'
			   END AS Kultura
			 , 'Самара' AS Olson
			 , COALESCE(f.approach, 1) AS approach
			 , CASE
				   WHEN t.roomtype_id IN ('об06', 'об10') THEN 'Общежитие'
				   WHEN (t.kol_occ = 1) THEN 'Отдельная квартира'
				   WHEN (t.kol_occ > 1) THEN 'Квартира коммунального заселения'
				   ELSE 'Отдельная квартира'
			   END AS ROOMTYPE
			 , CASE
					WHEN COALESCE(f.CadastralNumber,'')='' THEN COALESCE(t.CadastralNumber, 'нет') 
					ELSE COALESCE(f.CadastralNumber,'нет') 
				END AS flat_CadastralNumber
			 , CASE
				   WHEN COALESCE(b.CadastralNumber, '') = '' THEN 'нет'
				   ELSE b.CadastralNumber
			   END AS build_CadastralNumber
			 , b.street_name
			 , b.nom_dom
			 , b.build_type -- 1-МКД, 4-Жилой дом, 5-Жилой дом блокированной застройки
			 , f.is_flat -- признак квартиры (а не машиноместа или др.)
			 , f.is_unpopulated  -- признак не жилого помещения
			 , f.nom_kvr_sort
		FROM dbo.View_buildings AS b
			JOIN dbo.Flats f ON b.id = f.bldn_id
			OUTER APPLY (
				SELECT MIN(roomtype_id) AS roomtype_id
					 , MIN(CadastralNumber) AS CadastralNumber
					 , COUNT(o.occ) AS kol_occ
					 , SUM(o.total_sq) AS total_sq
					 , SUM(o.living_sq) AS living_sq
					 , SUM(o.Rooms) AS kol_rooms
					 , SUM(o.kol_people) AS kol_people
				FROM dbo.Occupations o
				WHERE o.flat_id = f.id
					AND o.status_id <> 'закр'
					AND o.total_sq > 0
				GROUP BY o.flat_id
			) t
		WHERE (@tip_id IS NULL OR b.tip_id = @tip_id)
			AND (b.id = @build_id OR (@build_id IS NULL AND b.is_paym_build = 1))
			AND (@is_flat IS NULL OR f.is_flat = @is_flat)
			AND t.kol_occ > 0
			AND (@sup_id IS NULL OR EXISTS (
				SELECT 1
				FROM Occ_Suppliers os
					JOIN dbo.Occupations o1 ON os.occ = o1.occ
				WHERE os.fin_id = b.fin_current
					AND o1.flat_id = f.id
					AND os.sup_id = @sup_id
					AND os.Debt <> 0
			))
	) AS t
	WHERE id_nom_gis =
					  CASE @only_new
						  WHEN 1 THEN ''
						  ELSE id_nom_gis
					  END

	ORDER BY adres
		   , t.nom_kvr_sort


END
go

