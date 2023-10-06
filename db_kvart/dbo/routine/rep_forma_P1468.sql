-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_forma_P1468]
(
    @fin_id SMALLINT,
    @tip_id SMALLINT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @t TABLE(
		build_id INT,
		tip_name VARCHAR(50),
		div_name VARCHAR(30) DEFAULT NULL,
		street_name VARCHAR(50),
		nom_dom VARCHAR(7),
		nom_dom_litera VARCHAR(5) DEFAULT '',
		godp SMALLINT DEFAULT NULL,
		levels SMALLINT DEFAULT NULL,
		vid_blag VARCHAR(150) DEFAULT NULL,
		total_sq DECIMAL(10, 4) DEFAULT 0,
		living_sq DECIMAL(10, 4) DEFAULT 0,
		arenda_sq DECIMAL(10, 4) DEFAULT 0,
		odn_sq DECIMAL(10, 4) DEFAULT NULL,
		kolFlats SMALLINT DEFAULT 0,
		kolFlatsIpu SMALLINT DEFAULT 0,
		kolFlatsNoIpu SMALLINT DEFAULT 0,
		kolPeople SMALLINT DEFAULT 0,
		kolPeopleIpu SMALLINT DEFAULT 0,
		kolPeopleNoIpu SMALLINT DEFAULT 0,
		kol_hvs DECIMAL(12, 6) DEFAULT 0,
		kol_gvs DECIMAL(12, 6) DEFAULT 0,
		kol_votv DECIMAL(12, 6) DEFAULT 0,
		kol_ee DECIMAL(12, 6) DEFAULT 0,
		kol_gaz DECIMAL(12, 6) DEFAULT 0,
		kol_hvs_opu DECIMAL(12, 6) DEFAULT 0,
		kol_gvs_opu DECIMAL(12, 6) DEFAULT 0,
		kol_votv_opu DECIMAL(12, 6) DEFAULT 0,
		kol_ee_opu DECIMAL(12, 6) DEFAULT 0,
		kol_gaz_opu DECIMAL(12, 6) DEFAULT 0
	)

	--=========================================================
	INSERT INTO @t (build_id
				  , tip_name
				  , div_name
				  , street_name
				  , nom_dom
				  , nom_dom_litera
				  , godp
				  , levels
				  , total_sq
				  , living_sq
				  , arenda_sq
				  , kolFlats
				  , kolFlatsIpu
				  , kolFlatsNoIpu
				  , kolPeople
				  , kolPeopleIpu
				  , kolPeopleNoIpu
				  , vid_blag)
	SELECT vb.id
		 , tip_name
		 , div_name
		 , street_name
		 , nom_dom
		 , CASE WHEN patindex('%[^0-9]%', nom_dom) = 0 THEN
				   '' ELSE
				   substring(nom_dom, patindex('%[^0-9]%', nom_dom), 5)
		   END as nom_dom_litera
		 , godp
		 , levels
		 , ds.Square
		 , ds.SquareLive
		 , coalesce(arenda_sq, 0)
		 , DS.CountFlats
		 , DS.CountFlatsIPU
		 , DS.CountFlatsNoIPU
		 , DS.CountPeople
		 , DS.CountPeopleIPU
		 , DS.CountPeopleNoIPU
		 , vid_blag= (SELECT vb1.name FROM dbo.VID_BLAG VB1 WHERE VB1.id=vb.vid_blag)
	FROM
		dbo.View_BUILDINGS vb
		JOIN DOM_SVOD DS
			ON vb.id = DS.build_id
	WHERE
		tip_id = COALESCE(@tip_id,tip_id)
		AND DS.fin_id = @fin_id

	SELECT voa.bldn_id
		 , service_id
		 , vp.is_counter
		 , S.is_build
		 , sum(kol) AS kol
	INTO
		#t2
	FROM
		dbo.View_PAYM vp 
		JOIN dbo.View_OCC_ALL voa 
			ON voa.fin_id = vp.fin_id AND voa.occ = vp.occ
		JOIN dbo.SERVICES S 
			ON vp.service_id = S.id
	WHERE
		voa.tip_id = COALESCE(@tip_id,tip_id)
		AND vp.fin_id = @fin_id
	GROUP BY
		voa.bldn_id
	  , service_id
	  , vp.is_counter
	  , S.is_build

	UPDATE t
	SET
		kol_hvs = (SELECT sum(t2.kol)
				   FROM
					   #t2 AS t2
				   WHERE
					   t2.bldn_id = t.build_id
					   AND service_id IN ('хвод', 'хвс2')
					   AND t2.is_build = 0
					   AND is_counter > 0), 
		kol_gvs = (SELECT sum(t2.kol)
				   FROM
					   #t2 AS t2
				   WHERE
					   t2.bldn_id = t.build_id
					   AND service_id IN ('гвод', 'гвс2')
					   AND t2.is_build = 0
					   AND is_counter > 0), 
		kol_votv = (SELECT sum(t2.kol)
					FROM
						#t2 AS t2
					WHERE
						t2.bldn_id = t.build_id
						AND service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
						AND t2.is_build = 0
						AND is_counter > 0), 
		kol_ee = (SELECT sum(t2.kol)
				   FROM
					   #t2 AS t2
				   WHERE
					   t2.bldn_id = t.build_id
					   AND service_id IN ('элек', 'эле2')
					   AND t2.is_build = 0
					   AND is_counter > 0), 
		kol_gaz = (SELECT sum(t2.kol)
				   FROM
					   #t2 AS t2
				   WHERE
					   t2.bldn_id = t.build_id
					   AND t2.service_id IN ('пгаз')
					   AND t2.is_build = 0
					   AND is_counter > 0), 
		--kol_hvs_opu = (SELECT sum(t2.kol)
		--			   FROM
		--				   #t2 AS t2
		--			   WHERE
		--				   t2.bldn_id = t.build_id
		--				   AND service_id IN ('хвсд', 'хвод')
		--				   AND t2.is_build = 1), 
		kol_hvs_opu = (SELECT sum(t2.value_source)
					   FROM
						   dbo.BUILD_SOURCE_VALUE AS t2
					   WHERE
						   t2.build_id = t.build_id
						   AND t2.service_id IN ('хвсд', 'хвод')
						   AND t2.fin_id = @fin_id),						   
		--kol_gvs_opu = (SELECT sum(t2.kol)
		--				FROM
		--					#t2 AS t2
		--				WHERE
		--					t2.bldn_id = t.build_id
		--					AND service_id IN ('гв2д', 'гвсд', 'гвод', 'гвс2')
		--					AND t2.is_build = 1),
		kol_gvs_opu = (SELECT sum(t2.value_source)
					   FROM
						   dbo.BUILD_SOURCE_VALUE AS t2 
					   WHERE
						   t2.build_id = t.build_id
						   AND t2.service_id IN ('гв2д', 'гвсд', 'гвод', 'гвс2')
						   AND t2.fin_id = @fin_id),
						   							 
		--kol_votv_opu = (SELECT sum(t2.kol)
		--			  FROM
		--				  #t2 AS t2
		--			  WHERE
		--				  t2.bldn_id = t.build_id
		--				  AND service_id IN ('канд', 'во2д', 'вотв', 'вот2')
		--				  AND t2.is_build = 1),
		kol_votv_opu = (SELECT sum(t2.value_source)
					   FROM
						   dbo.BUILD_SOURCE_VALUE AS t2 
					   WHERE
						   t2.build_id = t.build_id
						   AND t2.service_id IN ('канд', 'во2д', 'вотв', 'вот2')
						   AND t2.fin_id = @fin_id),						   
		--kol_ee_opu = (SELECT sum(t2.kol)
		--			  FROM
		--				  #t2 AS t2
		--			  WHERE
		--				  t2.bldn_id = t.build_id
		--				  AND service_id IN ('элек', 'Эдом', 'Эдм2', 'эле2')
		--				  AND t2.is_build = 1),
		kol_ee_opu = (SELECT sum(t2.value_source)
					   FROM
						   dbo.BUILD_SOURCE_VALUE AS t2 
					   WHERE
						   t2.build_id = t.build_id
						   AND t2.service_id IN ('элек', 'Эдом', 'Эдм2', 'эле2')
						   AND t2.fin_id = @fin_id),		 
        --kol_gaz_opu = (SELECT sum(t2.kol)
					   --FROM
						  -- #t2 AS t2
					   --WHERE
						  -- t2.bldn_id = t.build_id
						  -- AND service_id IN ('пгаз')
						  -- AND t2.is_build = 1)
		kol_gaz_opu = (SELECT sum(t2.value_source)
					   FROM
						   dbo.BUILD_SOURCE_VALUE AS t2 
					   WHERE
						   t2.build_id = t.build_id
						   AND t2.service_id IN ('пгаз')
						   AND t2.fin_id = @fin_id)						  
	FROM
		@t AS t


	SELECT *
	FROM
		@t
	ORDER BY
		street_name
	  , dbo.Fun_SortDom(nom_dom)
END
go

