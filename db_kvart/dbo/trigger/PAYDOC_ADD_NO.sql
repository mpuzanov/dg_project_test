CREATE   TRIGGER [dbo].[PAYDOC_ADD_NO]
ON [dbo].[Paydoc_packs]
FOR INSERT
AS
SET NOCOUNT ON
/*
	При закрытом платежном периоде вводить новые пачки нельзя
*/
DECLARE @name VARCHAR(50)

SELECT TOP (1)
	@name = ot.name
FROM INSERTED AS i
JOIN dbo.Occupation_Types ot
	ON ot.id = i.tip_id
WHERE ot.ras_paym_fin_new = cast(0 as bit)
AND ot.PaymClosed = cast(1 as bit)

IF (@name IS NOT NULL)
BEGIN
	RAISERROR ('При закрытом платежном периоде в <%s> вводить пачки нельзя!', 16, 10, @name)
	ROLLBACK TRAN
	RETURN
END

UPDATE t
SET pack_uid = dbo.fn_newid()
FROM INSERTED i
JOIN Paydoc_packs AS t ON 
	t.id = i.id
WHERE i.pack_uid IS NULL
go

