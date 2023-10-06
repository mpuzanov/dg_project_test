-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[ka_vibor_build_p354]
(
	@fin_id1 SMALLINT
	,@builds_str VARCHAR(4000)
	,@service_id1 VARCHAR(10) = NULL	
)
AS
/*

Exec ka_vibor_build_p354 @fin_id1=247, @service_id1='отоп', @builds_str='6806;6842;6906;6795;6866;6901;6903;6900;6902;6899;6898;6904;6865;6869;6867;6868'

Exec ka_vibor_build_p354 @fin_id1=247, @service_id1='тепл', @builds_str='6806;6842;6906;6795;6866;6901;6903;6900;6902;6899;6898;6904;6865;6869;6867;6868'

Exec ka_vibor_build_p354 @fin_id1=247, @service_id1='хвод', @builds_str='6806;6842;6906;6795;6866;6901;6903;6900;6902;6899;6898;6904;6865;6869;6867;6868'

Exec ka_vibor_build_p354 @fin_id1=247, @service_id1='гвод', @builds_str='6806;6842;6906;6795;6866;6901;6903;6900;6902;6899;6898;6904;6865;6869;6867;6868'

*/
BEGIN
	SET NOCOUNT ON;

	-- 1. создать таблицу с домами из списка кодов
	DECLARE @t_builds TABLE (id INT, adres VARCHAR(100), is_boiler BIT, arenda_sq DECIMAL(9,2), volume_arenda DECIMAL(15,4), volume_gvs DECIMAL(15,4))	
	INSERT INTO @t_builds(id, adres, is_boiler, arenda_sq)
	SELECT [value], b.adres, b.is_boiler, b.arenda_sq
	FROM STRING_SPLIT(@builds_str, ';') as t
		JOIN dbo.View_buildings_lite as b ON b.id=t.[value] AND b.is_paym_build=1
	WHERE RTRIM(t.value) <> ''

	UPDATE t SET arenda_sq=ba.arenda_sq, volume_arenda=ba.kol, volume_gvs=ba.volume_gvs
	FROM @t_builds as t
	JOIN dbo.Build_arenda AS ba ON t.id=ba.build_id
	WHERE ba.fin_id = @fin_id1
	AND ba.service_id=@service_id1

	DECLARE @t_services TABLE (build_id INT, service_id VARCHAR(10), is_mode BIT, is_direct_contract BIT DEFAULT 0 NOT NULL)
	
	INSERT INTO @t_services(build_id, service_id, is_mode, is_direct_contract) 
	SELECT t.id, @service_id1, 0, COALESCE(sb.is_direct_contract,0)
	FROM @t_builds t
	LEFT JOIN dbo.Services_build as sb ON t.id=sb.build_id AND sb.service_id=@service_id1


	IF @service_id1='гвод'
		INSERT INTO @t_services(build_id, service_id) SELECT id, 'хвод'	FROM @t_builds WHERE is_boiler=1

	IF @service_id1='тепл'
		INSERT INTO @t_services(build_id, service_id) SELECT id, 'отоп'	FROM @t_builds WHERE is_boiler=1

	-- исключить дома с услугой где режим только - НЕТ
	UPDATE t
	SET is_mode=1
	FROM @t_services t
	WHERE EXISTS(SELECT 1 FROM dbo.Paym_list p
		WHERE p.build_id=t.build_id AND p.service_id=t.service_id 
		AND ((p.mode_id%1000)<>0) OR p.service_id in ('элек','гвод','хвод','отоп','тепл'))

	-- выбрать по этим домам объёмы по ОДПУ
	SELECT
		t.id
		,t.adres
		,@service_id1 AS service_id
		,COALESCE(t.is_boiler,CAST(0 AS BIT)) AS is_boiler
		,s.is_direct_contract AS is_direct_contract		
		,MAX(COALESCE(t.arenda_sq,0)) AS arenda_sq
		,MAX(COALESCE(t.volume_gvs,0)) AS volume_gvs
		,SUM(COALESCE(ci.actual_value,0)) AS actual_value
		,SUM(COALESCE(ci.volume_arenda,0)) + MAX(COALESCE(t.volume_arenda,0)) AS volume_arenda
		,SUM(COALESCE(ci.volume_odn,0)) AS volume_odn
		,SUM(COALESCE(ci.norma_odn,0)) AS norma_odn
		,SUM(COALESCE(ci.volume_direct_contract,0)) AS volume_direct_contract
		,serv_dom=(select top(1) id from dbo.services where PATINDEX(@service_id1+'%',serv_from)>0 order by sort_no)
	FROM @t_builds AS t
		JOIN dbo.COUNTERS c ON t.id=c.build_id
		JOIN @t_services as s ON t.id=s.build_id AND c.service_id=s.service_id
		LEFT JOIN dbo.COUNTER_INSPECTOR ci ON c.id = ci.counter_id AND ci.fin_id=@fin_id1		
	WHERE c.date_del IS NULL
		AND c.is_build=1
		AND s.is_mode=1
	GROUP BY t.id
		,t.adres
		,t.is_boiler
		,s.is_direct_contract
	ORDER BY t.adres

	
END
go

