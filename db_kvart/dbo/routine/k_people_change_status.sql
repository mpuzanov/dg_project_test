-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_people_change_status]
(
	@occ INT
)
AS
/*
Проверяем не закончился ли статус регистрации у людей на лицевом счёте
Дата окончания должна быть в прошлом месяце
*/
BEGIN

	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT
				*
			FROM dbo.PEOPLE
			WHERE occ = @occ
			AND Del = 0
			AND dateEnd IS NOT NULL
			AND status2_id <> 'пост'
			AND AutoDelPeople = 2)
	BEGIN
		RETURN
	END

	--PRINT 'Смена истёкшего статуса регистрации'

	DECLARE @TablePeople TABLE
		(
			id			INT	PRIMARY KEY
			,occ		INT
			,comments	VARCHAR(50)
		)

	INSERT
	INTO @TablePeople
	(	id
		,occ
		,comments)
			SELECT
				p.id
				,p.occ
				,SUBSTRING('Стат.рег.' + dbo.Fun_InitialsPeople(p.id) + '(' + ps.short_name + ' до ' + CONVERT(VARCHAR(8), p.dateEnd, 3) + ')', 1, 50) AS comments
			FROM [dbo].[PEOPLE] AS p 
			JOIN dbo.OCCUPATIONS AS o 
				ON p.occ = o.occ
			JOIN dbo.OCCUPATION_TYPES AS ot 
				ON o.tip_id = ot.id
			JOIN dbo.GLOBAL_VALUES AS gb 
				ON o.fin_id = gb.fin_id
			JOIN dbo.PERSON_STATUSES AS ps
				ON p.status2_id = ps.id
			WHERE o.occ = @occ
			AND dateEnd IS NOT NULL
			AND p.Del = 0
			AND dateEnd < gb.start_date
			AND p.status2_id <> 'пост'
			AND ot.payms_value = 1
			AND p.AutoDelPeople = 2

	UPDATE p
	SET	status2_id		= 'пост'
		,dateEnd		= NULL
		,AutoDelPeople	= NULL
	FROM dbo.PEOPLE AS p
	JOIN @TablePeople AS p2
		ON p.id = p2.id

	INSERT
	INTO dbo.OP_LOG 
	(	user_id
		,op_id
		,occ
		,done
		,comments)
			SELECT
				NULL
				,'смчл'
				,occ
				,CAST(CURRENT_TIMESTAMP AS DATE)
				,comments
			FROM @TablePeople

END
go

