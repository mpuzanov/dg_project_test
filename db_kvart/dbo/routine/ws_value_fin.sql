-- ============================================================
-- Author:		Пузанов
-- Create date: 20.10.2016
-- Description:	Выгрузка в XML -формате по списку типов фонда
-- ============================================================
CREATE       PROCEDURE [dbo].[ws_value_fin]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@xml1		VARCHAR(MAX)	= '' OUTPUT
	,@fin_id2	SMALLINT		= NULL
	,@sup_id	INT				= NULL
)
AS
/*

declare @xml VARCHAR(MAX)
exec ws_value_fin 169,'28', @xml OUT, 169, 323
select @xml


Описание полей

tip_name -- тип фонда
street_name -- улица
nom_dom -- номер дома
bldn_id -- код дома
nom_kvr -- помещение
occ -- лицевой счет
start_date -- фин.период
service_id -- код услуги
tarif -- тариф
SALDO -- нач.сальдо
Value -- начислено
Discount -- льгота
Added -- перерасчеты
Paid -- пост.начисления (value-discount+added)
Paymaccount -- оплачено без пени
PaymAccount_peny -- оплачено пени
Debt      -- конечное сальдо
Penalty_old  -- итоговое за пред.периоды
Penalty_serv -- новое пени

*/
BEGIN

	SET NOCOUNT ON;

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	DECLARE @tip_table TABLE
		(
			tip_id SMALLINT DEFAULT NULL
		)

	INSERT
	INTO @tip_table
			SELECT CASE
                       WHEN Value = 'Null' THEN NULL
                       ELSE Value
                       END
			FROM STRING_SPLIT(@tip_str1, ',') WHERE RTRIM(value) <> ''

	IF EXISTS (SELECT
				1
			FROM @tip_table
			WHERE tip_id IS NULL)
	BEGIN  -- Заносим все типы жилого фонда
		DELETE FROM @tip_table
		INSERT
		INTO @tip_table
				SELECT
					id
				FROM dbo.VOCC_TYPES
	END
	--select * from @tip_table
	--************************************************************************************


	SELECT
		tip_name = REPLACE(vbl.tip_name, '"', ' ')
		,vbl.street_name
		,vbl.nom_dom
		,o.bldn_id -- код дома
		,o.nom_kvr
		,o.occ -- лицевой счет
		,o.start_date
		,pl.service_id -- код услуги
		--,cl.mode_id -- код режима потребления 
		,pl.tarif -- тариф
		,pl.saldo -- нач.сальдо
		,pl.Value -- начислено
		,pl.discount -- льгота
		,pl.added -- перерасчеты
		,pl.paid -- пост.начисления (value-discount+added)
		,Paymaccount = pl.Paymaccount - pl.PaymAccount_peny
		,pl.PaymAccount_peny
		,pl.debt      -- конечное сальдо
		,COALESCE(pl.Penalty_old, 0) AS Penalty_old
		,COALESCE(pl.Penalty_serv, 0) AS Penalty_serv
	INTO #t
	FROM dbo.View_OCC_ALL_LITE AS o 
	JOIN dbo.View_PAYM AS pl 
		ON pl.occ = o.occ
		AND pl.fin_id = o.fin_id
	JOIN dbo.View_BUILDINGS_LITE AS vbl 
		ON o.build_id = vbl.id
	WHERE o.fin_id BETWEEN @fin_id1 AND @fin_id2
	AND pl.fin_id BETWEEN @fin_id1 AND @fin_id2
	AND (pl.sup_id = @sup_id
	OR (pl.sup_id = 0
	AND @sup_id IS NULL))
	AND EXISTS (SELECT
			1
		FROM @tip_table
		WHERE tip_id = o.tip_id)
	--ORDER BY o.bldn_id


	SET @xml1 = (SELECT
			*
		FROM #t
		FOR XML RAW ('VALUE'), ROOT ('root'))

	SELECT
		*
	FROM #t
	ORDER BY street_name, dbo.Fun_SortDom(nom_dom), dbo.Fun_SortDom(nom_kvr)

END
go

