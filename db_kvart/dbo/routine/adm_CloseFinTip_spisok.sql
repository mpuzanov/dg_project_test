-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_CloseFinTip_spisok]
(
	@tip_id_str VARCHAR(4000) -- строка формата: Код типа фонда;Код типа фонда;Код типа фонда;Код типа фонда
)
AS
BEGIN
	/*
	Закрываем заданные фин. периоды
	
	exec adm_CloseFinTip_spisok '1;2;3;4;5;6'
	
	*/
	SET NOCOUNT ON;

	DECLARE @tip_id INT;

	DECLARE cur CURSOR LOCAL FOR
		SELECT
			*
		FROM STRING_SPLIT(@tip_id_str, ';')
		WHERE RTRIM(Value) <> ''

	OPEN cur;
	FETCH NEXT FROM cur INTO @tip_id;

	WHILE @@fetch_status = 0
	BEGIN

		--RAISERROR ('EXEC adm_CloseFinPeriod_tip %i', 10, 1, @tip_id) WITH NOWAIT;

		EXEC adm_CloseFinPeriod_tip @tip_id=@tip_id, @debug=0

		FETCH NEXT FROM cur INTO @tip_id;
	END

	CLOSE cur;
	DEALLOCATE cur;
END
go

