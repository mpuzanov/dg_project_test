-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	
-- =============================================
CREATE   PROCEDURE [dbo].[k_StrsumPaymUks]
(
	@occ			INT
	,@fin_id		SMALLINT
	,@tip_paym_id	VARCHAR(10)
	,@comments		VARCHAR(50)		= ''
	,@ResStr		VARCHAR(100)	OUT
	,@SumPaymUks	DECIMAL(9, 2)	= 0 OUT
)
AS
/*
declare @ResStr VARCHAR(100),@SumPaymUks DECIMAL(9, 2)
EXEC k_StrsumPaymUks 700233376,141,'1021','переданного в',@ResStr OUT,@SumPaymUks OUT
select ResStr=@ResStr,SumPaymUks=@SumPaymUks
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE	@source_name	VARCHAR(50)
			,@tip_paym		VARCHAR(50)  -- тип платежа


	SELECT TOP 1
		@source_name = source_name
		,@tip_paym = tip_paym
		,@SumPaymUks = SUM(value)
	FROM dbo.View_PAYINGS 
	WHERE fin_id = @fin_id
	AND occ = @occ
	AND tip_paym_id = @tip_paym_id
	GROUP BY	occ
				,source_name
				,tip_paym

	IF @SumPaymUks IS NULL
		SET @SumPaymUks = 0

	IF @SumPaymUks = 0
		SET @ResStr = ''
	ELSE
		SET @ResStr = @tip_paym + ' ' + @comments + ' ' + @source_name + ' ' + STR(@SumPaymUks, 9, 2)

END
go

