-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_added_payments_subsid]
	ON [dbo].[Added_Payments]
	FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;


	IF EXISTS (
			SELECT 1
			FROM INSERTED AS I
			WHERE I.add_type = 15
		)
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM INSERTED AS I
					JOIN dbo.Subsidia12 AS s12 
						ON I.fin_id = s12.fin_id
						AND I.Occ = s12.Occ
						AND I.service_id = s12.service_id
			)
		BEGIN
			UPDATE s12
			SET sub12 = sum_value
			FROM dbo.Subsidia12 AS s12
				JOIN (
					SELECT I.fin_id
						 , I.Occ
						 , I.service_id
						 , SUM(I.Value) AS sum_value
					FROM dbo.Added_Payments AS I
					WHERE I.add_type = 15
					GROUP BY I.fin_id
						   , I.Occ
						   , I.service_id
				) AS t ON t.fin_id = s12.fin_id
					AND t.Occ = s12.Occ
					AND t.service_id = s12.service_id
			WHERE s12.sub12 <> sum_value
		END
		ELSE
		BEGIN
			INSERT INTO Subsidia12 (fin_id
								  , Occ
								  , service_id
								  , value_max
								  , Value
								  , Paid
								  , sub12)
			SELECT i1.fin_id
				 , i1.Occ
				 , i1.service_id
				 , 0
				 , 0
				 , 0
				 , i1.Value
			FROM INSERTED AS i1
				LEFT JOIN dbo.Subsidia12 AS t2 
					ON t2.fin_id = i1.fin_id
					AND t2.Occ = i1.Occ
					AND t2.service_id = i1.service_id
			WHERE i1.add_type = 15
				AND t2.service_id IS NULL
		END
	END

END
go

