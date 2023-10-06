-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Установка ставки ЦБ в базе (из внешних программ)
-- =============================================
CREATE       PROCEDURE [dbo].[adm_set_key_rate]
(
	  @set_date SMALLDATETIME
	, @StavkaCB DECIMAL(9,2)
	, @is_write_global BIT = 0  -- устанавливать последний процент в текущий период
)
AS
/*
exec adm_set_key_rate @set_date='20220214', @StavkaCB=9.5, @is_write_global=0

exec adm_set_key_rate @set_date='20211006', @StavkaCB=6.7500

*/
BEGIN
	SET NOCOUNT ON;

	SET @is_write_global=COALESCE(@is_write_global,0)

	DECLARE @last_stavka DECIMAL(10, 4)

	SELECT TOP (1) @last_stavka = [val_proc]
	FROM Peny_procent
	WHERE [data] < @set_date
	ORDER BY data DESC

	--PRINT 'last_stavka='+STR(@last_stavka,9,4)+' StavkaCB='+STR(@StavkaCB,9,4)

	-- проверим в истории ставок ЦБ
	IF @StavkaCB <> @last_stavka
	BEGIN
		--PRINT 'merge'

		MERGE INTO dbo.Peny_procent AS Target USING (VALUES(@set_date, @StavkaCB)) AS Source ([DATE], StavkaCB)
		ON Target.[data] = Source.[DATE]
		WHEN MATCHED
			THEN UPDATE
				SET [val_proc] = Source.StavkaCB
		WHEN NOT MATCHED BY Target
			THEN INSERT ([data]
					   , [val_proc])
				VALUES([DATE]
					 , StavkaCB);
	END

	IF @is_write_global=1
	BEGIN
		-- проверим в последнем фин.периоде
		DECLARE @fin_id_last SMALLINT
			  , @start_date SMALLDATETIME
			  , @end_date SMALLDATETIME

		SELECT TOP (1) @fin_id_last = fin_id
					 , @start_date = gv.start_date
					 , @end_date = gv.end_date
					 , @last_stavka = gv.StavkaCB
		FROM dbo.Global_values gv
		ORDER BY gv.fin_id DESC

		IF @set_date > @start_date
			UPDATE dbo.Global_values
			SET StavkaCB = @StavkaCB
			WHERE fin_id = @fin_id_last
	END


END
go

