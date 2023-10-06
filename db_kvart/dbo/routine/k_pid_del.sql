-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Удаление ПИД
-- =============================================
CREATE PROCEDURE [dbo].[k_pid_del]
(
@id int
)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM dbo.PID where id=@id

END
go

