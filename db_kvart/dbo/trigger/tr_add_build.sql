-- =============================================
-- Author:		Пузанов	
-- Create date: 11.07.2011
-- Description:	Устанавливаем начальный фин.период в доме
-- =============================================
CREATE       TRIGGER [dbo].[tr_add_build]
ON [dbo].[Buildings]
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT
				1
			FROM INSERTED)
		RETURN;

	UPDATE b
	SET fin_current = ot.fin_id
		, date_create = current_timestamp
		, build_uid = CASE WHEN i.build_uid IS NULL THEN dbo.fn_newid() ELSE i.build_uid END
	FROM Buildings AS b
	JOIN INSERTED AS i
		ON b.id = i.id
	JOIN dbo.Occupation_Types AS ot
		ON i.tip_id = ot.id

END
go

