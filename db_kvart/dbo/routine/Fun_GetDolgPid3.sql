-- =============================================
-- Author:		Пузанов
-- Create date: 23.12.2014
-- Description:	Получаем долг по рассрочке платежа
-- =============================================
CREATE FUNCTION [dbo].[Fun_GetDolgPid3]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
/*
SELECT dbo.Fun_GetDolgPid3(680001666,152,NULL)
SELECT dbo.Fun_GetDolgPid3(680001666,152,323)
*/
RETURNS DECIMAL(9, 2)
AS
BEGIN
	DECLARE @dolg DECIMAL(9, 2) = 0

	IF @sup_id IS NOT NULL
		SELECT
			@dolg = saldo - PaymAccount
		FROM dbo.OCC_SUPPLIERS OS
		WHERE occ = @occ
		AND sup_id = @sup_id
		AND fin_id = @fin_id
	ELSE
		SELECT
			@dolg = saldo - PaymAccount
		FROM dbo.View_OCC_ALL AS o
		WHERE occ = @occ
		AND fin_id = @fin_id

	RETURN COALESCE(@dolg, 0)
END
go

