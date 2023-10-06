-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetSubsidia12]
(
	@fin_id			SMALLINT
	,@occ			INT
	,@service_id	VARCHAR(10)	= NULL
	,@sup_id		INT		= NULL
)
RETURNS DECIMAL(9, 2)
AS
/*
select dbo.Fun_GetSubsidia12(138,980170101,null,null)
*/
BEGIN
	RETURN COALESCE(

	(SELECT
		SUM(S.sub12)
	FROM dbo.SUBSIDIA12 S
	JOIN dbo.View_CONSMODES_ALL cl
		ON S.fin_id = cl.fin_id
		AND S.Occ = cl.Occ
		AND S.service_id = cl.service_id
	WHERE S.fin_id = @fin_id
	AND S.Occ = @occ
	AND (S.service_id = @service_id OR @service_id IS NULL)
	AND (cl.sup_id = @sup_id OR @sup_id IS null)

	), 0)

END
go

