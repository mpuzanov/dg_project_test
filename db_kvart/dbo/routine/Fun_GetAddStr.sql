-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2011
-- Description:	Получаем строку документов перерасчётов по лицевому счёту
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAddStr]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL
	, @sup_id INT = NULL
	, @service_id VARCHAR(10) = NULL
)
RETURNS VARCHAR(800)
/*
Возврат строки документов с перерасчётами

select [dbo].[Fun_GetAddStr](100837,239,null,null)
select [dbo].[Fun_GetAddStr](100837,239,null,'одэж')
select [dbo].[Fun_GetAddStr](100837,238,null,null)

*/
AS
BEGIN

	DECLARE @StrAdds VARCHAR(800) = ''

	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @StrAdds = STUFF((
			SELECT CONCAT(',' 
			, CASE WHEN (ap.doc = '' AND @service_id IS NOT NULL) THEN MAX(ap.comments) ELSE ap.doc END
			)
			FROM dbo.View_added_lite AS ap
				JOIN dbo.Added_Types at ON ap.add_type = at.id
			WHERE ap.occ = @occ1
				AND ap.fin_id = @fin_id1
				AND ap.sup_id = COALESCE(@sup_id, 0)
				AND (ap.service_id = @service_id OR @service_id IS NULL)
				AND (ap.doc <> '' OR ap.comments <> '')
				AND ap.value <> 0
				AND at.visible_kvit = CAST(1 AS BIT)
			GROUP BY ap.doc
			--HAVING SUM(ap.VALUE)<>0	 -- общая сумма по документу <>0   Нужно даже если = 0
			FOR XML PATH ('')
		), 1, 1, '')

	IF @StrAdds <> ''
		SET @StrAdds = N'Перерасчёты:' + @StrAdds

	RETURN @StrAdds

END
go

