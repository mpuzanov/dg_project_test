-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                       PROCEDURE [dbo].[rep_gis_occ]
(
	@tip_id			 SMALLINT = NULL
   ,@build_id		 INT	  = NULL
   ,@sup_id			 INT	  = NULL
   ,@occ_and_sup_all BIT	  = 0  -- выборка и обычных лицевых и поставщиков
   ,@only_new		 BIT	  = 0  -- только где не заполнено поле id_jku_gis
   ,@is_flat		 BIT	  = NULL -- только жилые помещения
)
AS
/*
exec rep_gis_occ 28,null,323,NULL,0
exec rep_gis_occ 28,1027,NULL,NULL,0
exec rep_gis_occ 28,1057,323,NULL,1
exec rep_gis_occ 28,1027,null,1,0
exec rep_gis_occ 28,1027,null,1,1

exec rep_gis_occ 132,null,365,NULL,1
exec rep_gis_occ 132,null,365,NULL,0
exec rep_gis_occ 132,null,null,NULL,1
exec rep_gis_occ 132,null,null,NULL,0


TYPE_OCC_GIS
id	name
1	ЛС УО
2	ЛС РСО
3	ЛС КР
4	ЛС ОГВ/ОМС

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @DB_NAME	 VARCHAR(20) = UPPER(DB_NAME())
		   ,@PROPTYPE_ID VARCHAR(10) = NULL

	IF @occ_and_sup_all IS NULL
		SET @occ_and_sup_all = 0
	IF @only_new IS NULL
		SET @only_new = 0

	IF (@DB_NAME <> 'NAIM'
		AND @tip_id IS NULL)
		SET @tip_id = -1
	IF (@DB_NAME = 'NAIM')
		SELECT
			@PROPTYPE_ID = 'непр'

	SELECT
		rownum = ROW_NUMBER() OVER (ORDER BY build_id, nom_kvr_sort, sup_id)
	   ,t.*
	   ,p.Last_name AS LastName
	   ,p.First_name AS FirstName
	   ,p.Second_name AS MiddleName
	   ,p.snils
	   ,DOC.DOCTYPE_ID
	   ,DOC.DOC_NO
	   ,DOC.PASSSER_NO
	   ,DOC.ISSUED
	FROM (SELECT
			CASE
				WHEN ot.export_gis_occ_prefix = 1 THEN	dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) 
				else o.occ
			END                        AS occ
		   ,COALESCE(o.id_jku_gis, '') AS id_jku
		   , CASE
                 WHEN @DB_NAME = 'NAIM' THEN 'ЛС ОГВ/ОМС'
                 ELSE tog.name
            END                        AS tip_occ
		   ,CASE
				WHEN @DB_NAME = 'NAIM' THEN NULL  --
				WHEN ot.tip_occ IN (3, 4) THEN NULL  -- ЛС КР , ЛС ОГВ/ОМС
				WHEN PROPTYPE_ID = 'непр' THEN 'Да'
				ELSE 'Нет'
			END                                                                       AS naim
		   ,COALESCE(o.id_els_gis, '')                                                AS id_els_gis
		   ,CASE
				WHEN COALESCE(r.id_room_gis, '')<>'' THEN r.id_room_gis
				ELSE COALESCE(o.id_nom_gis, '') 
			END     AS id_nom_gis
		   --,COALESCE(o.id_nom_gis, '') AS id_nom_gis
		   ,o.TOTAL_SQ
		   ,CASE WHEN o.LIVING_SQ>o.TOTAL_SQ THEN o.TOTAL_SQ ELSE o.LIVING_SQ END AS LIVING_SQ
		   , CASE
                 WHEN o.TEPLO_SQ > o.TOTAL_SQ THEN o.TOTAL_SQ
                 ELSE o.TEPLO_SQ
            END     AS TEPLO_SQ
		   ,o.kol_people
		   , CASE
                 WHEN COALESCE(r.id_room_gis, '') <> '' THEN CONCAT(o.address , ', комн.' , r.name)
                 ELSE o.address
            END     AS address 
		   ,b.nom_dom
		   ,CASE
				WHEN LEFT(COALESCE(LTRIM(o.prefix), ''), 1) = '&' THEN REPLACE(o.prefix, '&', '')
				ELSE o.nom_kvr
			END     AS nom_kvr
		   ,b.kod_fias
		   ,b.adres AS adres_build
		   ,b.id    AS build_id
		   ,o.nom_kvr_sort
		   ,0       AS sup_id
		   ,CASE 
				WHEN (o.PROPTYPE_ID='арен') OR o.roomtype_id IN ('парк','клад','офис','бокс','коля') THEN 'Нежилое помещение'
				ELSE 'Жилое помещение'
			END AS typ_kvr
		   ,o.roomtype_id 
		   ,b.fin_current AS fin_id
		   ,o.occ AS occ_id
		   ,o.is_flat
		   ,o.is_unpopulated
		   ,r.name AS nom_room
		   ,r.id_room_gis
		   ,r.CadastralNumber as room_CadastralNumber
		FROM dbo.Vocc AS o 
		JOIN dbo.View_buildings_lite AS b 
			ON o.build_id = b.id
		JOIN dbo.Occupation_types AS ot 
			ON o.tip_id = ot.id
		LEFT JOIN dbo.Type_occ_gis tog 
			ON ot.tip_occ = tog.id
		LEFT JOIN dbo.Rooms as r 
			ON o.room_id = r.id
		WHERE 
			(@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@build_id IS NULL OR o.build_id = @build_id)
			AND ((@occ_and_sup_all = CAST(0 AS BIT)	AND @sup_id IS NULL) OR (@occ_and_sup_all = CAST(1 AS BIT)))
			AND ot.export_gis = CAST(1 AS BIT)
			AND o.STATUS_ID <> 'закр'
			AND ((ot.is_export_gis_without_paid=0 AND o.TOTAL_SQ > 0) OR ot.is_export_gis_without_paid=1)
			AND b.is_paym_build = CAST(1 AS BIT)
			AND (@PROPTYPE_ID IS NULL OR o.PROPTYPE_ID = @PROPTYPE_ID)
			AND (@is_flat IS NULL OR o.is_flat = @is_flat)
			AND COALESCE(b.kod_fias,'')<>'' -- 02.06.2023

		UNION ALL

		SELECT
			os.occ_sup AS occ
		   ,COALESCE(os.id_jku_gis, '') AS id_jku
		   ,tog.name AS tip_occ
		   ,CASE
				WHEN sa.tip_occ IN (3, 4) THEN NULL
				WHEN PROPTYPE_ID = 'непр' THEN 'Да'
				ELSE 'Нет'
			END AS naim
		   ,COALESCE(o.id_els_gis, '') AS id_els_gis
		   ,COALESCE(o.id_nom_gis, '') AS id_nom_gis
		   ,o.TOTAL_SQ
		   ,o.LIVING_SQ
		   ,o.TEPLO_SQ
		   ,o.kol_people
		   ,o.address
		   ,b.nom_dom
		   ,CASE
				WHEN LEFT(COALESCE(LTRIM(o.prefix), ''), 1) = '&' THEN REPLACE(o.prefix, '&', '')
				ELSE o.nom_kvr
			END AS nom_kvr
		   ,b.kod_fias
		   ,b.adres AS adres_build
		   ,b.id AS build_id
		   ,nom_kvr_sort
		   ,os.sup_id AS sup_id
		   ,CASE 
				WHEN (o.PROPTYPE_ID='арен') OR o.roomtype_id IN ('парк','клад','офис','бокс','коля') THEN 'Нежилое помещение'
				ELSE 'Жилое помещение'
			END AS typ_kvr
		   ,o.roomtype_id
		   ,o.fin_id
		   ,o.occ AS occ_id
		   ,o.is_flat
		   ,o.is_unpopulated
		   ,r.name AS nom_room
		   ,r.id_room_gis
		   ,r.CadastralNumber as room_CadastralNumber
		FROM dbo.Vocc AS o 
			JOIN dbo.Occ_suppliers AS os
				ON o.occ = os.occ AND os.fin_id = o.fin_id
			JOIN dbo.Occupation_types AS ot 
				ON o.tip_id = ot.id			
			JOIN dbo.View_BUILDINGS_LITE AS b
				ON o.build_id = b.id
			JOIN dbo.Suppliers_all sa 
				ON os.sup_id = sa.id
			LEFT JOIN dbo.Type_occ_gis tog 
				ON sa.tip_occ = tog.id
			LEFT JOIN dbo.Rooms as r 
				ON o.room_id = r.id
		WHERE 
			(@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@build_id IS NULL OR o.build_id = @build_id)
			AND ((@occ_and_sup_all = 0	AND @sup_id IS NOT NULL	AND os.sup_id = @sup_id) OR (@occ_and_sup_all = CAST(1 AS BIT)))
			AND (@is_flat IS NULL OR o.is_flat = @is_flat)
			AND o.STATUS_ID <> 'закр'
			AND o.TOTAL_SQ > 0
			--AND (os.saldo<>0 OR os.paid<>0 OR os.paymaccount<>0 OR os.debt<>0)
			AND b.is_paym_build = 1
			AND NOT EXISTS (SELECT
					1
				FROM dbo.SUPPLIERS_TYPES st
				WHERE st.tip_id = ot.id
					AND st.sup_id = os.sup_id
					AND st.export_gis = CAST(0 AS BIT))
			AND NOT EXISTS (SELECT
					1
				FROM dbo.SUPPLIERS_BUILD sb
				WHERE sb.build_id = o.build_id
					AND sb.sup_id = os.sup_id
					AND sb.gis_blocked = CAST(1 AS BIT))
			) AS t
	LEFT JOIN dbo.INTPRINT i
		ON t.occ_id = i.occ
		AND t.fin_id = i.fin_id
	LEFT JOIN dbo.PEOPLE p 
		ON i.Initials_owner_id = p.id
	LEFT JOIN dbo.IDDOC DOC
		ON DOC.owner_id = p.id
		AND DOC.active = CAST(1 AS BIT)
	WHERE (id_els_gis =
		CASE @only_new
			WHEN 1 THEN ''
			ELSE id_els_gis
		END)
	OR (id_jku =
		CASE @only_new
			WHEN 1 THEN ''
			ELSE id_jku
		END)
	ORDER BY build_id, nom_kvr_sort, sup_id


END
go

