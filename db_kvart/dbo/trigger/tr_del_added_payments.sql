-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_del_added_payments]
ON [dbo].[Added_Payments]
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT
				1
			FROM DELETED AS D
			WHERE D.add_type = 15)
	BEGIN

		UPDATE s12
		SET sub12 = t.sum_value
		FROM dbo.Subsidia12 AS s12
		JOIN (SELECT
				ap.fin_id
				,ap.occ
				,ap.service_id
				,SUM(ap.value) AS sum_value
			FROM dbo.Added_Payments AS ap
			WHERE ap.add_type = 15
			GROUP BY ap.fin_id
					,ap.occ
					,ap.service_id
			) AS t ON 
				t.fin_id = s12.fin_id
				AND t.occ = s12.occ
				AND t.service_id = s12.service_id
		WHERE s12.sub12 <> sum_value
		
		DELETE s12 -- если нет Субсидий в текущих разовых и в истории - то удаляем
		FROM DELETED AS d
		JOIN dbo.Subsidia12 AS s12	ON 
			d.fin_id = s12.fin_id
			AND d.occ = s12.occ
			AND d.service_id = s12.service_id
		LEFT JOIN dbo.Added_Payments ap ON 
			ap.fin_id = s12.fin_id
			AND ap.occ = s12.occ
			AND ap.service_id = s12.service_id
			AND ap.add_type = 15
		LEFT JOIN dbo.Added_Payments_History APH ON 
			APH.fin_id = s12.fin_id
			AND APH.occ = s12.occ
			AND APH.service_id = s12.service_id
			AND APH.add_type = 15
		WHERE d.add_type = 15
			AND ap.service_id IS NULL
			AND APH.service_id IS NULL			
	END

END
go

