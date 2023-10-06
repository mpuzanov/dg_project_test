-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Удаление группы уведомлений
-- =============================================
CREATE       PROCEDURE [dbo].[adm_pid_del]
(
	@tip_id			SMALLINT
	,@sup_id		INT
	,@pid_tip		SMALLINT		= 1 -- 1-Уведомление о задолженности
	,@data_create	SMALLDATETIME	= NULL
	,@data_end		SMALLDATETIME	= NULL -- конечная дата удаления документов
	,@debug			BIT				= 0
	,@CountResult	INT				= 0 OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@fin_id		SMALLINT
			,@occ		INT	= 0
			,@id		INT
			,@i			INT	= 0
			,@y			INT	= 0
			,@er		INT
			,@strerror	VARCHAR(800)

	IF @data_end IS NULL SET @data_end=@data_create

	DECLARE curs CURSOR LOCAL FOR

		SELECT
			p.occ
			,p.id
		FROM dbo.PID AS p 
		JOIN dbo.View_OCC_ALL AS o 
			ON p.fin_id = o.fin_id
			AND p.occ = o.occ
		WHERE 
			o.tip_id = COALESCE(@tip_id, o.tip_id)
			AND p.sup_id = COALESCE(@sup_id, p.sup_id)
			AND p.data_create BETWEEN COALESCE(@data_create, p.data_create) AND COALESCE(@data_end, p.data_create)

	OPEN curs
	FETCH NEXT FROM curs INTO @occ, @id
	WHILE (@@fetch_status = 0)
	BEGIN
		SET @i = @i + 1
		IF @debug = 1 --PRINT STR(@i)+' '+STR(@occ)
			RAISERROR (' %d  %d', 10, 1, @i, @occ) WITH NOWAIT;

		EXEC @er = dbo.k_pid_del @id = @id
		IF @er <> 0
		BEGIN
			SET @y = @y + 1
			IF @y < 6
			BEGIN
				SET @strerror = 'Ошибка при удалении ПИД по лицевому: ' + STR(@occ) + ' с кодом: ' + STR(@id)
				EXEC dbo.k_adderrors_card @strerror
			END
		END

		FETCH NEXT FROM curs INTO @occ, @id
	END
	CLOSE curs
	DEALLOCATE curs

	SELECT
		@CountResult = @i

END
go

