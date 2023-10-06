CREATE   PROCEDURE [dbo].[rep_flat_modes]
(
	@build_id INT
)
AS
	--
	-- Информация о квартирах в доме
	-- Отчет: flat_modes.fr3
	-- 
	--
	SET NOCOUNT ON


	SELECT
		o.occ
		,o.floor
		,o.rooms
		,o.nom_kvr
		,RTRIM(address) AS address
		,roomtype_id
		,proptype_id
		,total_sq
		,dbo.Fun_Initials(o.occ) AS Initials
		,dbo.Fun_PersonStatusStr(o.occ) AS People
		,dbo.Fun_LgotaStr(o.occ) AS Lgota
		,dbo.Fun_SubsidStr(o.occ) as Subsid
	FROM dbo.VOCC AS o 
	WHERE o.bldn_id = @build_id
	ORDER BY o.nom_kvr_sort
go

