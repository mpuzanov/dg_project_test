-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Создание договора на основе одного дома
-- =============================================
CREATE   PROCEDURE [dbo].[adm_dog_add_build]
(
    @dog_id       VARCHAR(20),
    @build_id     INT,
    @sup_id       INT,
    @first_occ    SMALLINT = NULL,
    @bank_account INT      = NULL,
    @id_accounts  INT      = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tip_id  SMALLINT,
            @fin_id  SMALLINT,
            @dog_int INT = NULL

	SELECT @tip_id = tip_id
		 , @fin_id = fin_current
	FROM
		dbo.BUILDINGS AS B
	WHERE
		B.id = @build_id

	SELECT @dog_int = id
	FROM
		dbo.dog_sup
	WHERE
		dog_id = @dog_id

	BEGIN TRAN

	IF @dog_int IS NULL
	BEGIN -- создаём договор
		INSERT INTO [dbo].[DOG_SUP] ([dog_id]
								   , [dog_name]
								   , [sup_id]
								   , [tip_id]
								   , [first_occ]
								   , [bank_account]
								   , [dog_date]
								   , [id_accounts]
								   , [date_edit]
								   , [login_edit]
								   , [data_start]
								   , [tip_name_dog]
								   , [is_cessia])
		VALUES
			(@dog_id, @dog_id, @sup_id, @tip_id, @first_occ, @bank_account, NULL, @id_accounts, current_timestamp, system_user, NULL, NULL, 0)

		SELECT @dog_int = scope_identity()
	END
	;
	MERGE dbo.DOG_BUILD AS db USING (SELECT @dog_int AS dog_int
										  , @fin_id AS fin_id
										  , @build_id AS build_id) AS t2 ON db.dog_int = t2.dog_int AND db.fin_id = t2.fin_id AND db.build_id = t2.build_id WHEN MATCHED THEN UPDATE
	SET
		dog_int = @dog_int, fin_id = @fin_id, build_id = @build_id
	WHEN NOT MATCHED THEN INSERT (dog_int, fin_id, build_id)
	VALUES
		(@dog_int, @fin_id, @build_id);

	COMMIT TRAN
END
go

