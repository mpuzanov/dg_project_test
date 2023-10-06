CREATE   PROCEDURE [dbo].[k_show_koef_2]
(
	@service_id1	VARCHAR(10)
	,@level1		INT	= NULL
	,@is_build1	 BIT = 0
)
AS
	/*
	
	k_show_koef_2 @service_id1='наем'
	k_show_koef_2 @service_id1='наем',@is_build1=1
	
	Показываем список возможных
	коэффициентов по услуге
	а также возможно по разделу(Этажность, лифт, Материал стен)
	
	*/
	SET NOCOUNT ON

	IF @is_build1 IS NULL
		SET @is_build1 = 0

	SELECT
		k.*
		,concat(name , ' /' , LTRIM(STR(value, 5, 3)) , '/') as name2
	FROM dbo.KOEF AS k 
	WHERE k.service_id = @service_id1
	AND k.level1 =
		CASE
			WHEN @level1 IS NULL THEN k.level1
			ELSE @level1
		END
	AND k.level2 != 0
	AND k.is_use=1
	AND k.is_build=@is_build1
go

