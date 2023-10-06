CREATE           PROC [dbo].[k_FileFTPSelect] 
    @occ INT
AS
SET NOCOUNT ON


SELECT f1.[id]
	 , f1.[occ]
	 , f1.[FileName]
	 , f1.[date_load]
	 , U.Initials AS [user_load]
	 , f1.[Comments]
	 , f1.FileSizeKb
	 , f1.file_edit
FROM dbo.FileFTP AS f1 
	LEFT JOIN dbo.Users AS U 
		ON f1.user_load = U.login
WHERE ([occ] = @occ)
ORDER BY f1.id DESC
go

