-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_add_occup_types]
   ON  [dbo].[Occupation_Types]
   FOR INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE ot
	SET [start_date] = CASE WHEN i.[start_date] is NULL THEN gb.start_date ELSE i.[start_date] END
	, tip_uid =	CASE WHEN i.tip_uid IS NULL THEN dbo.fn_newid() ELSE i.tip_uid END
	from dbo.Occupation_Types as ot
		JOIN inserted as i ON 
			ot.id=i.id
		JOIN dbo.GLOBAL_VALUES as gb ON 
			i.fin_id=gb.fin_id
	WHERE ot.start_date is null

END
go

