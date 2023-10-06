-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_update_SUPPLIERS_ALL]
   ON [dbo].[Suppliers_all]
FOR INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;


	UPDATE t
	SET sup_uid = dbo.fn_newid()
	FROM INSERTED i
	JOIN Suppliers_all AS t ON 
        t.id = i.id
	WHERE i.sup_uid IS NULL

	IF EXISTS (SELECT
				1
			FROM INSERTED
			WHERE penalty_calc = cast(1 as bit)
			AND (COALESCE(penalty_metod,0)=0 OR COALESCE(LastPaym,0) = 0))
	BEGIN
		RAISERROR ('Заполните все поля для расчёта пени', 16, 1);	
		ROLLBACK TRAN
		RETURN 
	END
END
go

