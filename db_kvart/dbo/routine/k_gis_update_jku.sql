-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	установить текущий id_jku_gis в старые периоды
-- =============================================
CREATE       PROCEDURE [dbo].[k_gis_update_jku]
(
	  @tip_id SMALLINT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- по единой квитанции
	--SELECT o2.*
	UPDATE o2
	SET id_jku_gis = o.id_jku_gis
	FROM dbo.Occupations o
		JOIN dbo.Occ_history o2 ON o2.occ = o.occ
			AND o2.fin_id < o.fin_id
	WHERE o.tip_id = @tip_id
		AND o2.fin_id >= (o2.fin_id - 12)
		--AND o2.id_jku_gis IS NULL
		AND o.id_jku_gis IS NOT NULL

	-- по поставщику
	--SELECT os2.*
	UPDATE os2
	SET id_jku_gis = os1.id_jku_gis
	FROM Occupations o
		JOIN dbo.Occ_Suppliers os1 ON os1.occ = o.occ
			AND os1.fin_id = o.fin_id
		JOIN dbo.Occ_Suppliers os2 ON os2.occ_sup = os1.occ_sup
			AND os2.fin_id < os1.fin_id
	WHERE o.tip_id = @tip_id
		AND os2.fin_id >= (os2.fin_id - 12)
		--AND os2.id_jku_gis IS NULL
		AND os1.id_jku_gis IS NOT NULL
END
go

