-- =============================================
-- Author:		Пузанов 
-- Create date: 
-- Description:	
-- =============================================
CREATE         TRIGGER [dbo].[update_TYPE_GIS_FILE]
ON [dbo].[Type_gis_file]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE tgf
	SET VersionInt =
			CAST((SELECT
				RIGHT('00'+value,3)
				FROM STRING_SPLIT(i.Version, '.')
				WHERE RTRIM(value) <> ''
				FOR XML PATH (''))
			AS BIGINT)
		, UserEdit = (SELECT u.Initials	FROM dbo.Users u WHERE u.login = system_user)
		, Name = concat('Шаблон ПД от ',
			CONVERT(varchar(12), i.[FileDateEdit], 104),
			case when coalesce(i.[Version],'')='' 
				then '' 
				else concat(', версия: ',i.[Version]) 
			end
			)
		, size_body = dbo.fsize(i.REPORT_BODY)
	FROM dbo.Type_gis_file tgf
	JOIN INSERTED AS i ON 
		tgf.id = i.id

END
go

