CREATE   PROCEDURE [dbo].[k_ulica]
(
	  @tip_id SMALLINT = NULL
	, @town_id SMALLINT = 1
	, @all BIT = 0
)
AS
/*
exec k_ulica @tip_id=28
exec k_ulica @town_id=4
exec k_ulica @all=1

SELECT SUSER_NAME()
EXECUTE AS LOGIN = 'repview'
SELECT SUSER_NAME()
exec k_ulica
REVERT
SELECT SUSER_NAME()
*/
SET NOCOUNT ON

	IF @tip_id = 0
		SET @tip_id = NULL
	IF @town_id = 0
		SET @town_id = NULL    
	IF @all IS NULL
		SET @all = 0

	IF @all = 1
		SELECT s.id
				, s.name
				, s.town_id
				, s.prefix
				, s.short_name
				, CONCAT(s.name , CASE
                                      WHEN s.town_id = 1 THEN ''
                                      ELSE CONCAT(' (', s.town_name, ')')
            END) as full_name
				--, s.kod_fias
				--, s.code
		FROM dbo.VStreets s
		WHERE (@town_id IS NULL OR s.town_id = @town_id)
		ORDER BY s.name
	ELSE
	IF dbo.Fun_User_readonly() = CAST(1 AS BIT)
		SELECT s.id
				, s.name
				, s.town_id
				, s.prefix
				, s.short_name
				, CONCAT(s.name , CASE
                                      WHEN s.town_id = 1 THEN ''
                                      ELSE CONCAT(' (', s.town_name, ')')
            END) as full_name
				--, s.kod_fias
				--, s.code
		FROM dbo.VStreets AS s
		WHERE EXISTS (
				SELECT 1
				FROM dbo.Buildings vb 
					JOIN dbo.VOcc_types_access AS vt ON vb.tip_id = vt.id
				WHERE (@tip_id IS NULL OR vb.tip_id = @tip_id)
					AND (@town_id IS NULL OR vb.town_id = @town_id)
					AND vb.street_id = s.id
			)
		ORDER BY s.name
	ELSE
		SELECT s.id
				, s.name
				, s.town_id
				, s.prefix
				, s.short_name
				, CONCAT(s.name , CASE
                                      WHEN s.town_id = 1 THEN ''
                                      ELSE CONCAT(' (', s.town_name, ')')
            END) as full_name
				--, s.kod_fias
				--, s.code
		FROM dbo.VStreets AS s 
		WHERE EXISTS (
				SELECT 1
				FROM dbo.Buildings vb 
				WHERE (@tip_id IS NULL OR vb.tip_id = @tip_id)
					AND (@town_id IS NULL OR vb.town_id = @town_id)
					AND vb.street_id = s.id
			)
		ORDER BY s.name
go

