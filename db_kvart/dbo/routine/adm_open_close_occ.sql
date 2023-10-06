-- =============================================
-- Author:		Пузанов
-- Create date: 22.06.2010
-- Description:	Открыть закрытый лицевой
-- =============================================
CREATE   PROCEDURE [dbo].[adm_open_close_occ]
(	
@occ1 INT
,@Result BIT = 0 OUTPUT 
)
AS
BEGIN
	SET NOCOUNT ON;
	
	ALTER TABLE dbo.Occupations DISABLE TRIGGER OCC_READONLY

	UPDATE o
	SET status_id='откр'
	FROM dbo.Occupations as o
	WHERE Occ=@occ1
		AND status_id='закр'

	SET @Result = @@ROWCOUNT

	ALTER TABLE dbo.Occupations ENABLE TRIGGER OCC_READONLY

END
go

