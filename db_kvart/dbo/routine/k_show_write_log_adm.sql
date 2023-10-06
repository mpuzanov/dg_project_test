CREATE   PROCEDURE [dbo].[k_show_write_log_adm]
(
	@op_id1		VARCHAR(10)	= NULL
	,@max_rows	BIT		= 0
)
AS
	/*
	Показываем историю глобальных(не по лицевым) изменений по базе
	*/
	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE @count_row INT
	IF @max_rows = 0
		SET @count_row = 50
	ELSE
		SET @count_row = 999999


	SELECT TOP (@count_row)
		'Имя пользователя' = SUBSTRING(u.Initials, 1, 25)
		,'Виды работ' = o.Name
		,'Дата' = op.done
		,'Комментарий' = op.comments
		--,'Дата строка'=convert(char(12), op.done, 106)
	FROM dbo.OP_LOG_ADM AS op 
	JOIN dbo.OPERATIONS AS o 
		ON op.op_id = o.op_id
	JOIN dbo.USERS AS u 
		ON op.user_id = u.id
	WHERE op.op_id =
		CASE
			WHEN @op_id1 IS NULL THEN op.op_id
			ELSE @op_id1
		END
	ORDER BY op.done DESC, op_no DESC
go

