-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_update_SUPPLIERS_BUILD]
ON [dbo].[Suppliers_build]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT
				NULL
			FROM INSERTED
			WHERE is_peny = 'Y'
			AND (COALESCE(penalty_metod,0)=0 OR lastday_without_peny = 0))
	BEGIN
		RAISERROR ('Заполните все поля для расчёта пени', 16, 1);	
		ROLLBACK TRAN
		RETURN
	END

END
go

