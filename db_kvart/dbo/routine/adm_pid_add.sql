-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[adm_pid_add]
(
	  @tip_id SMALLINT
	, @sup_id INT
	, @pid_tip SMALLINT = 1 -- 1-Уведомление о задолженности
	, @data_create SMALLDATETIME = NULL
	, @data_end SMALLDATETIME = NULL
	, @summaDolga DECIMAL(9, 2) = 0
	, @debug BIT = 0
	, @CountResult INT = 0 OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_id SMALLINT
		  , @occ INT = 0
		  , @occ_sup INT
		  , @summa DECIMAL(9, 2)
		  , @i INT = 0
		  , @y INT = 0
		  , @er INT
		  , @strerror VARCHAR(800)
		  , @date1 DATETIME
		  , @pid_add SMALLINT

	IF @summaDolga IS NULL
		SET @summaDolga = 0

	DECLARE curs CURSOR LOCAL FOR

		SELECT o.occ
			 , os.occ_sup
			 , saldo =
					  CASE
						  WHEN @sup_id IS NOT NULL THEN os.saldo
						  ELSE o.saldo
					  END
			 , o.fin_id
		FROM dbo.Occupations AS o
			LEFT JOIN dbo.Occ_Suppliers AS os ON 
				os.fin_id = o.fin_id
				AND os.occ = o.occ
		WHERE 
			o.tip_id = COALESCE(@tip_id, o.tip_id)
			AND os.sup_id = COALESCE(@sup_id, os.sup_id)

	OPEN curs
	FETCH NEXT FROM curs INTO @occ, @occ_sup, @summa, @fin_id

	WHILE (@@fetch_status = 0)
	BEGIN

		IF @debug = 1 --PRINT STR(@i)+' '+STR(@occ)
			RAISERROR (' %d  %d', 10, 1, @i, @occ) WITH NOWAIT;

		SET @pid_add = 0
		IF @summa > @summaDolga
		BEGIN
			EXEC @er = dbo.k_pid_add @fin_id = @fin_id
								   , @occ = @occ
								   , @sup_id = @sup_id
								   , @summa = @summa
								   , @pid_tip = @pid_tip
								   , @occ_sup = @occ_sup
								   , @data_create = @data_create
								   , @data_end = @data_end
								   , @Res = @pid_add OUTPUT

			IF @er <> 0
			BEGIN
				SET @y = @y + 1
				IF @y < 6
				BEGIN
					SET @strerror = 'Ошибка при формировании ПИД по лицевому: ' + STR(@occ)
					EXEC dbo.k_adderrors_card @strerror
				END
			END
		END

		IF @pid_add > 0
			SET @i = @i + 1

		FETCH NEXT FROM curs INTO @occ, @occ_sup, @summa, @fin_id
	END

	CLOSE curs
	DEALLOCATE curs

	SELECT @CountResult = @i

END
go

