CREATE   PROCEDURE [dbo].[k_global_values]
(
	  @fin_id1 INT = NULL  -- по умолчанию последний фин.период
)
AS
/*
	Выдаем список глобальных значений 
*/
	SET NOCOUNT ON

	IF COALESCE(@fin_id1, 0) = 0
		SELECT TOP (1) *
		FROM dbo.Global_values
		ORDER BY fin_id DESC
	ELSE
		SELECT *
		FROM dbo.Global_values
		WHERE fin_id = @fin_id1
go

