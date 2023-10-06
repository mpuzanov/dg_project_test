CREATE   TRIGGER [dbo].[tr_update_occup_types]
	ON [dbo].[Occupation_Types]
	FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (
			SELECT d.fin_id
			FROM DELETED d
			INTERSECT  -- выводит одинаковые записи
			SELECT i.fin_id
			FROM INSERTED i
		)
	BEGIN
		UPDATE b
		SET fin_current = i.fin_id
		FROM [dbo].[Buildings] AS b
			JOIN dbo.Occupation_Types AS ot ON b.tip_id = ot.id
			JOIN INSERTED AS i ON ot.id = i.id
		WHERE b.is_finperiod_owner=cast(0 as bit)
	END

	IF NOT EXISTS (
			SELECT d.state_id
			FROM DELETED d
			INTERSECT  -- выводит одинаковые записи
			SELECT i.state_id
			FROM INSERTED i
		)
	BEGIN
		INSERT INTO dbo.Occupation_Types_Log (tip_id
											, day_time
											, log_state_id)
		SELECT i.id
			 , current_timestamp
			 , i.state_id
		FROM dbo.Occupation_Types AS ot
			JOIN INSERTED AS i ON ot.id = i.id
	END

	IF NOT EXISTS (
			SELECT d.id_accounts
			FROM DELETED d
			INTERSECT  -- выводит одинаковые записи
			SELECT i.id_accounts
			FROM INSERTED i
		)
	BEGIN
		INSERT INTO dbo.Reports_account_types (tip_id
											 , id_account)
		SELECT i.id
			 , i.id_accounts
		FROM INSERTED AS i
			LEFT JOIN dbo.Reports_account_types AS ra ON ra.tip_id = i.id
				AND ra.id_account = i.id_accounts
		WHERE ra.id_account IS NULL
	END

	UPDATE ot
	SET ot.start_date = gv.start_date
	FROM dbo.Occupation_Types AS ot
		JOIN Global_values gv ON ot.fin_id = gv.fin_id
		JOIN INSERTED AS i ON ot.id = i.id
	WHERE ot.start_date <> gv.start_date

END
go

