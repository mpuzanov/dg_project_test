-- =============================================
-- Author:		Пузанов
-- Create date: 06.05.2022
-- Description:	Изменение наименования документа у перерасчёта
-- =============================================
CREATE     PROCEDURE [dbo].[ka_copy_added]
	  @id INT -- код разового для копирования
	, @ZapUpdate INT = 0 OUTPUT
AS
BEGIN
SET NOCOUNT ON

INSERT INTO dbo.Added_Payments
(occ
	 , service_id
	 , sup_id
	 , add_type
	 , value
	 , doc
	 , data1
	 , data2
	 , Hours
	 , add_type2
	 , manual_bit
	 , Vin1
	 , Vin2
	 , doc_no
	 , doc_date
	 , user_edit
	 , dsc_owner_id
	 , fin_id_paym
	 , date_edit
	 , comments
	 , tnorm2
	 , kol
	 , fin_id
	 , repeat_for_fin)
SELECT occ
	 , service_id
	 , sup_id
	 , add_type
	 , value
	 , doc
	 , data1
	 , data2
	 , Hours
	 , add_type2
	 , manual_bit
	 , Vin1
	 , Vin2
	 , doc_no
	 , doc_date
	 , user_edit
	 , dsc_owner_id
	 , fin_id_paym
	 , date_edit
	 , comments
	 , tnorm2
	 , kol
	 , fin_id
	 , repeat_for_fin
FROM dbo.Added_Payments AS ap
WHERE ap.id = @id
SELECT @ZapUpdate = @@rowcount

END
go

