-- =============================================
-- Author:		Пузанов 
-- Create date: 
-- Description:	
-- =============================================
CREATE     TRIGGER [dbo].[update_GIS_SHABLONS]
ON [dbo].[Gis_shablons]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE tgf
	SET [VersionInt] =
		CAST((SELECT
			RIGHT('00'+value,3)
			FROM STRING_SPLIT(tgf.Versia, '.')
			WHERE RTRIM(value) <> ''
			FOR XML PATH (''))
		AS BIGINT)
		,UserEdit = (SELECT
				u.Initials
			FROM dbo.USERS u
			WHERE u.login = system_user)
	   ,DateEdit = current_timestamp
	FROM [dbo].[GIS_SHABLONS] tgf
	JOIN INSERTED AS d
		ON tgf.id = d.id

END
go

