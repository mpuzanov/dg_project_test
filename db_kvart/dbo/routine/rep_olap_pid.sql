-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_olap_pid]
(
	@tip_id		SMALLINT
	,@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@sup_id	SMALLINT	= NULL
	,@build		INT			= NULL
	,@debug		BIT			= NULL
)
AS
/*

rep_olap_pid 28,165,165,null,null,1

*/
BEGIN
	SET NOCOUNT ON;

	IF @tip_id IS NULL
		SET @tip_id = 0

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1


	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	SELECT
		p.occ AS 'Лицевой'
		,pt.name AS 'Тип ПИД'
		,p.data_create AS 'Дата создания'
		,p.data_end AS 'Дата окончания'
		,p.Summa AS 'Сумма'
		,gv.start_date AS 'Период'
		,p.kol_mes AS 'Кол.месяцев'
		,dbo.Fun_InitialsPeople(p.owner_id) AS 'ФИО'
		,o.tip_name AS 'Тип фонда'
		,o.address AS 'Адрес'
		,(vbl.street_name + ' д.' + vbl.nom_dom) AS 'Адрес дома'
		,vsa.name AS 'Поставщик'
		,vbl.sector_name AS 'Участок'
		,p.occ_sup AS 'Лицевой поставщика'
		,p.date_edit AS 'Дата изм.'
		,P.SumPeny AS 'Сумма пени'
		,P.PenyPeriod1 AS 'Период пени с'
		,P.PenyPeriod2 AS 'Период пени по'
		,P.SumDolg AS 'Сумма задолженности'
		,P.DolgPeriod1 AS 'Период долга с'
		,P.DolgPeriod2 AS 'Период долга по'
		,P.GosTax AS 'Госпошлина'		 
		,dbo.Fun_GetFIOLoginUser(p.user_edit) AS 'Пользователь'
		--,gv.StrMes AS 'Фин_период_стр'
		--,p.pid_tip
		--,p.dog_int
		,p.sup_id
		,p.id AS 'Код'
	FROM dbo.PID AS p
	JOIN dbo.PID_TYPES pt
		ON p.pid_tip = pt.id
	JOIN dbo.VOCC AS o
		ON p.occ = o.occ
	JOIN dbo.View_BUILDINGS_LITE vbl
		ON o.bldn_id = vbl.id
	JOIN dbo.GLOBAL_VALUES gv 
		ON p.fin_id = gv.fin_id
	LEFT JOIN dbo.View_SUPPLIERS_ALL vsa
		ON p.sup_id = vsa.id
	WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
	AND (p.sup_id = @sup_id
	OR @sup_id IS NULL)
	AND (o.tip_id = @tip_id
	OR @tip_id IS NULL)
	AND (o.bldn_id = @build
	OR @build IS NULL)
END
go

