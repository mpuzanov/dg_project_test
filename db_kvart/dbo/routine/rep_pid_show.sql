-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_pid_show]
(
	@date1		SMALLDATETIME
	,@date2		SMALLDATETIME	= NULL
	,@pid_tip	SMALLINT		= NULL
	,@sup_id	INT				= NULL
	,@tip_id	SMALLINT		= NULL
	,@sector_id	SMALLINT		= NULL
)
AS
/*

rep_pid_show '20151101',NULL,4,null,28

*/
BEGIN
	SET NOCOUNT ON;

	IF @date2 IS NULL
		SET @date2 = '20500101'


	SELECT
		p.occ
		,pt.name AS pid_tip_name
		,p.data_create
		,p.data_end
		,p.Summa
		,dbo.Fun_GetNameFinPeriod(p.fin_id) AS FinPeriod
		,p.kol_mes
		,dbo.Fun_InitialsPeople(p.owner_id) AS FIO
		,o.tip_name AS tip_name
		,o.address
		,vsa.name as sup_name
		,vbl.sector_name
		,p.date_edit
		,dbo.Fun_GetFIOLoginUser(p.user_edit) AS user_edit
		,p.pid_tip
		,p.occ_sup
		,p.dog_int
		,p.sup_id
		,p.id
	FROM [dbo].[PID] AS p
	JOIN dbo.PID_TYPES pt
		ON p.pid_tip = pt.id
	JOIN [dbo].[VOCC] AS o
		ON p.occ = o.occ
	JOIN dbo.View_BUILDINGS_LITE vbl 
		ON o.bldn_id = vbl.id
	LEFT JOIN dbo.View_SUPPLIERS_ALL vsa 
		ON p.sup_id = vsa.id
	WHERE p.pid_tip = COALESCE(@pid_tip, p.pid_tip)
	AND p.data_create BETWEEN @date1 AND @date2
	AND p.sup_id = COALESCE(@sup_id, p.sup_id)
	AND o.tip_id = COALESCE(@tip_id, o.tip_id)
	AND vbl.sector_id = COALESCE(@sector_id, vbl.sector_id)
--AND p.fin_id = 165
END
go

