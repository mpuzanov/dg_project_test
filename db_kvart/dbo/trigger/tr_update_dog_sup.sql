-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_update_dog_sup]
    ON [dbo].[Dog_sup]
    FOR INSERT, UPDATE
    AS
BEGIN
	SET	NOCOUNT ON;
	
	UPDATE	ds
	SET
	  date_edit = current_timestamp
    , login_edit = system_user
    , dog_name = 
    	CASE
			WHEN COALESCE(ds.dog_name,'') IN ('', '! Новый') THEN 
			CASE
				WHEN i.dog_date IS NOT NULL
	            	THEN CONCAT(i.dog_id , ' от ' , CONVERT(VARCHAR(12), i.dog_date, 104))
				ELSE i.dog_id
			END
			ELSE ds.dog_name
		END
	FROM
		dbo.DOG_SUP AS ds
		JOIN INSERTED AS i
        	ON ds.dog_id = i.dog_id
END
go

