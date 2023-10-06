-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_pid_show1]
(
	@occ		INT
	,@sup_id	INT			= NULL
	,@pid_tip	SMALLINT	= NULL
)
AS
/*
k_pid_show1 680002900, NULL, 4

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_id SMALLINT
	SELECT
		@fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	SELECT
		p.id
		,P.occ
		,P.occ_sup
		,p.pid_tip
		,p.data_create --'Дата создания'
		,p.data_end -- 'Дата окончания'
		,p.Summa --'Сумма'
		,p.kol_mes
		,p.sup_id
		,p.owner_id
		,dbo.Fun_InitialsPeople(p.owner_id) AS owner_name
		,SA.name AS sup_name
		,pt.name AS pidtype_name
		,p.date_edit
		,u.Initials AS [user_name]
		,P.court_id
		,c.name AS court_name
		,P.SumPeny
		,P.PenyPeriod1
		,P.PenyPeriod2
		,P.GosTax
		,P.SumDolg
		,P.DolgPeriod1
		,P.DolgPeriod2		
	FROM dbo.PID AS p
	LEFT JOIN dbo.SUPPLIERS_ALL SA 
		ON p.sup_id = SA.id
	JOIN dbo.PID_TYPES pt 
		ON p.pid_tip = pt.id
	LEFT JOIN dbo.USERS u
		ON p.user_edit = u.login
	LEFT JOIN dbo.COURTS c 
		ON p.court_id=c.id
	WHERE p.Occ = @occ
	AND (sup_id=@sup_id or @sup_id IS null)
	AND (pid_tip = @pid_tip OR @pid_tip IS NULL)

END
go

