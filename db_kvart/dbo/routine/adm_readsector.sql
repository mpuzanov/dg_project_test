CREATE   PROCEDURE [dbo].[adm_readsector]
(
	@tip1 SMALLINT = NULL
)
AS
	SET NOCOUNT ON

	IF @tip1 IS NULL
		SELECT DISTINCT
			s.*
		   ,CONCAT(LTRIM(STR(s.id)) , '  ' , s.name) AS name2
		FROM dbo.SECTOR AS s 
		JOIN dbo.SECTOR_TYPES AS st 
			ON s.id = st.sector_id
		JOIN dbo.VOCC_TYPES vt 
			ON st.tip_id = vt.id
		ORDER BY s.id
	ELSE
		SELECT
			s.*
		   ,CONCAT(LTRIM(STR(s.id)) , '  ' , s.name) AS name2
		FROM dbo.SECTOR AS s 
		JOIN dbo.SECTOR_TYPES AS st 
			ON s.id = st.sector_id
		JOIN dbo.VOCC_TYPES vt
			ON st.tip_id = vt.id
		WHERE st.tip_id = @tip1
		ORDER BY s.id
go

