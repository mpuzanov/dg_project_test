-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   FUNCTION [dbo].[fn_get_tips_tf]
(
@tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
, @tip_id SMALLINT = NULL
, @build INT = NULL
)
RETURNS 
	@tbl TABLE (tip_id SMALLINT PRIMARY KEY)
AS
/*
select * from dbo.fn_get_tips_tf('1',1,null)
select * from dbo.fn_get_tips_tf('131,2',1,null)
select * from dbo.fn_get_tips_tf(null,null,6767)
select * from dbo.fn_get_tips_tf('',null,null)
*/
BEGIN

	SELECT @tip_str1 = CONCAT(
			COALESCE(@tip_str1,''), 
			(SELECT ',' + LTRIM(STR(b.tip_id))
			FROM dbo.Buildings as b
			WHERE 
				(b.id = @build OR @build IS NULL)
				AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			GROUP BY b.tip_id
			FOR XML PATH ('')) )
			
	INSERT INTO @tbl(tip_id)
	SELECT DISTINCT vs.id
	FROM dbo.VOcc_types AS vs
		OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
	WHERE @tip_str1 IS NULL OR t.value=vs.id
	
	RETURN 
END
go

