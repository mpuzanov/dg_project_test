CREATE   PROCEDURE [dbo].[k_history]
(
	  @occ1 INT
	, @p1 INT -- выбор истории 
	, @p2 INT = 0 -- параметр по истории начислений
	, @max_rows BIT = 0
	, @p3 INT = NULL -- доп. параметр по истории начислений 
)
AS
	/*
	exec k_history 78996,7,0
	exec k_history 680001155, 2,165
		
	Возможные значения @P1
	1 - История проживающих
	2 - История начислений
	3 - История редактирования
	4 - История субсидий
	5 - История платежей
	6 - История льгот
	7 - История лиц. счета
	8 - История разовых
	9 - Удаленные субсидии
	10 - Изменение пени
	11 - История режимов потребления
	12 - История начислений по счетчикам
	13 - История разовых по счетчикам
	14 - История по человеку
	15 - История начислений по услугам по лицевому
	16 - История по поставщикам
	17 - История начислений по ОПУ
	18 - История по людям
	19 - История приборов учёта
	20 - История итогов по лицевым счетам
	21 - История платежей по чекам
	22 - Раскидка платежа по услугам (в Картотеке)
	23 - Комментарии по дому и л/счёту  (в Картотеке)
	24 - Водоотведение по ХВС/ГВС по л/счёту
	*/
	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE @count_row INT = 999
		  , @login VARCHAR(30) = system_user

	IF @p1 = 0
		SET @p1 = 1
	IF @p3 = 0
		SET @p3 = NULL

	IF @max_rows = 0
		AND @p2 = 0
		SET @count_row = 37

	DECLARE @Only_sup BIT = 0

	IF EXISTS (
			SELECT 1
			FROM dbo.Users_sup AS US
			WHERE sysuser = @login
		)
		SET @Only_sup = 1

	--**************************************************************************************************
	--region 1 История проживающих
	IF @p1 = 1
	BEGIN
		SELECT TOP (@count_row) p.Last_name AS 'Фамилия'
							  , p.First_name AS 'Имя'
							  , p.Second_name AS 'Отчество'
							  , CONVERT(VARCHAR(15), p.Birthdate, 106) AS 'День рожд.'
							  , CONVERT(VARCHAR(15), p.DateReg, 106) AS 'Дата регистр.'
							  , CONVERT(VARCHAR(15), p.DateDel, 106) AS 'Дата выписки'
							  , CONVERT(VARCHAR(15), p.DateEnd, 106) AS 'Дата оконч.рег.'
							  , ps.name AS 'Последний статус регистрации'
							  , SUBSTRING(re.name, 1, 30) AS 'Причина выписки'
							  , CONVERT(VARCHAR(15), p.DateDeath, 106) AS 'Дата смерти'
							  , CONVERT(VARCHAR(15), p.DateEdit, 106) AS 'Дата изм.'
							  , (SUBSTRING(LTRIM(RTRIM(CONCAT(KraiNew , ' ' , RaionNew , ' ' , TownNew , ' ' , VillageNew , ' ' , StreetNew , ' ' , Nom_domNew , ' ' , Nom_kvrNew))), 1, 50)) AS 'Адрес выписки'
							  , p.id AS 'Код'
							  , p.Initials_people AS 'ФИО'
		FROM dbo.VPeople AS p 
			JOIN dbo.Reason_extract AS re ON COALESCE(p.Reason_extract, 0) = re.id
			JOIN dbo.Person_statuses AS ps ON p.Status2_id = ps.id
			LEFT JOIN dbo.People_2 AS p2 ON p.id = p2.owner_id
		WHERE Occ = @occ1
			AND Del = CAST(1 AS BIT)
		ORDER BY DateDel DESC
	END
	--endregion
	--**************************************************************************************************
	--region 2.0 История начислений Суммарные значения по финансовым периодам
	IF (@p1 = 2)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) cp.StrFinPeriod AS 'Фин.период'
							  , MIN(sa.name) AS 'Поставщик'
							  , CASE
                                    WHEN p.sup_id > 0 THEN MIN(p.occ_sup_paym)
                                    ELSE MIN(p.Occ)
								END AS 'Лицевой'
							  , CAST(SUM(p.SALDO) AS MONEY) AS 'Вх.Сальдо'
							  , CAST(SUM(p.Value) AS MONEY) AS 'Начислено'
								--, CAST(SUM(p.discount) AS MONEY) AS 'Льгота'
								--,CAST(SUM(p.compens) AS MONEY) AS 'Субсидия'
							  , CAST(SUM(p.Added) AS MONEY) AS 'Перерасчет'
							  , CAST(SUM(p.Paid) AS MONEY) AS 'Итого начисл.'
							  , CAST(SUM(p.PaymAccount) AS MONEY) AS 'Оплатил'
							  , SUM(p.PaymAccount_peny) AS 'из них пени'
							  , CAST(SUM(p.PaymAccount - p.PaymAccount_peny) AS MONEY) AS 'Оплата без пени'
							  , CAST(SUM(p.Debt) AS MONEY) AS 'Кон. сальдо'
							  , CAST(SUM(p.penalty_prev) AS MONEY) AS 'Пени прошл'
							  , CAST(SUM(p.Penalty_old) AS MONEY) AS 'Пени прошл изм'
							  , CAST(SUM(COALESCE(p.penalty_serv, 0)) AS MONEY) AS 'Пени новое'
							  , CAST(SUM(p.penalty_serv + p.Penalty_old) AS DECIMAL(9, 2)) AS 'Пени'
								--,YEAR(o.start_date) AS 'Год'					   
							  , p.account_one AS 'Отд.квит.'
								--,CAST(SUM(COALESCE(p.penalty_old,0) + COALESCE(p.penalty_serv,0)) AS MONEY) AS 'Пени итог'
							  , p.fin_id AS 'id'
							  , CONVERT(VARCHAR(7), MAX(cp.start_date), 126) AS 'Период'
		FROM dbo.Paym_history AS p 
			JOIN dbo.Calendar_period cp ON p.fin_id = cp.fin_id
			JOIN dbo.View_services_access AS vs ON vs.id = p.service_id -- для ограничения доступа 
			LEFT JOIN dbo.Suppliers_all AS sa ON p.sup_id = sa.id
		WHERE p.Occ = @occ1
		GROUP BY p.fin_id
			   , cp.StrFinPeriod
			   , p.sup_id --sa.name
			   , p.account_one
		ORDER BY p.fin_id DESC
	END
	--endregion
	--region 2.1 История начислений.  Значения по заданному фин.периоду
	IF (@p1 = 2)
		AND (@p2 <> 0)
	BEGIN

		SELECT CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN 'Всего'
				   WHEN (GROUPING([Услуга]) = 1) THEN 'Итого по ' --+ [Поставщик]
				   ELSE coalesce(MAX([Фин.период]), '????')
			   END AS [Фин.период]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   ELSE coalesce([Поставщик], '????')
			   END AS 'Поставщик'
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL --'Всего'
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL --'Итого по ' + [Поставщик]
				   ELSE coalesce([Услуга], '????')
			   END AS [Услуга]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   --WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Лицевой])
			   END AS [Лицевой]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Кол-во])
			   END AS [Кол-во]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Тариф])
			   END AS [Тариф]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Коэф.])
			   END AS [Коэф.]
			 , SUM([Вх.Сальдо]) AS [Вх.Сальдо]
			 , SUM([Начислено]) AS [Начислено]
			   --, SUM([t].[Льгота]) AS [Льгота]
			 , NULLIF(SUM([Перерасчет]), 0) AS [Перерасчет]
			 , NULLIF(SUM([Кол-во разовых]), 0) AS [Кол-во разовых]
			 , SUM([Ит.начисл.]) AS [Ит.начисл.]
			 , SUM([Оплатил]) AS [Оплатил]
			 , NULLIF(SUM([из них пени]), 0) AS [из них пени]
			 , SUM([Оплата без пени]) AS [Оплата без пени]
			 , SUM([Кон. сальдо]) AS [Кон. сальдо]

			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Ед.изм.])
			   END AS [Ед.изм.]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Метод])
			   END AS [Метод]
			 , CASE
				   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				   ELSE MAX([Кол-во норма])
			   END AS [Кол-во норма]
			 --, CASE
				--   WHEN (GROUPING([Поставщик]) = 1) THEN NULL
				--   WHEN (GROUPING([Услуга]) = 1) THEN NULL
				--   ELSE MAX([Признак расч.пени])
			 --  END AS [Признак расч.пени]

			 , NULLIF(SUM([Пени прошл]), 0) AS [Пени прошл]
			 , NULLIF(SUM([Пени прошл изм]), 0) AS [Пени прошл изм]
			 , NULLIF(SUM([Пени новое]), 0) AS [Пени новое]
			 , NULLIF(SUM([Пени прошл изм] + [Пени новое]), 0) AS [Пени итог]
			 , MAX([Дата начала]) AS [Дата начала]
			 , MAX([Дата окончания]) AS [Дата окончания]
			 , MAX([Коэф_Дней]) AS [Коэф_Дней]
		FROM (
			SELECT CASE
					   WHEN p.account_one = 1 THEN p.sup_id --101+s.service_no
					   ELSE 1
				   END AS 'Код'
				 , cp.StrFinPeriod AS 'Фин.период'
				 , CASE
                       WHEN p.sup_id > 0 THEN p.occ_sup_paym
                       ELSE p.Occ
                END AS 'Лицевой'
				 , SUBSTRING(s.short_name, 1, 30) AS 'Услуга'
				 , p.tarif AS 'Тариф'
				 , p.Koef AS 'Коэф.'
				 , p.kol AS 'Кол-во'
				 , p.SALDO AS 'Вх.Сальдо'
				 , p.[Value] AS 'Начислено'
				 , p.Discount AS 'Льгота'
				 , p.Compens AS 'Субсидия'
				 , p.Added AS 'Перерасчет'
				 , p.kol_added AS 'Кол-во разовых'
				 , p.Paid AS 'Ит.начисл.'
				 , CAST(p.PaymAccount AS MONEY) AS 'Оплатил'
				 , p.PaymAccount_peny AS 'из них пени'
				 , CAST((p.PaymAccount - p.PaymAccount_peny) AS MONEY) AS 'Оплата без пени'
				 , p.Debt AS 'Кон. сальдо'
				 , met1.name AS 'Метод'
				 , p.account_one AS 'Отд.квит.'
				 , kol_norma AS 'Кол-во норма'
				 , met2.name AS 'Метод стар'
				 , U.short_id AS 'Ед.изм.'
				 , p.account_one
				 , s.service_no
				 , p.penalty_prev AS 'Пени прошл'
				 , p.Penalty_old AS 'Пени прошл изм'
				 , COALESCE(p.penalty_serv, 0) AS 'Пени новое'
				 , COALESCE(sa.name, '-') AS 'Поставщик'
				 , p.date_start AS 'Дата начала'
				 , p.date_end AS 'Дата окончания'
				 , p.koef_day AS 'Коэф_Дней'
			FROM dbo.View_paym AS p 
				JOIN dbo.View_services_access AS s ON 
					p.service_id = s.id
				JOIN Calendar_period cp ON 
					cp.fin_id = p.fin_id
				LEFT JOIN dbo.Units U ON 
					p.unit_id = U.id
				LEFT JOIN dbo.Suppliers_all AS sa ON 
					p.sup_id = sa.id
				LEFT JOIN dbo.view_metod as met1 ON 
					p.metod=met1.id
				LEFT JOIN dbo.view_metod as met2 ON 
					p.metod_old=met2.id
			WHERE p.Occ = @occ1
				AND p.fin_id = @p2
				AND (@p3 IS NULL OR p.occ_sup_paym = @p3)
		) AS t
		GROUP BY ROLLUP ([Поставщик], [Услуга])
	--ORDER BY [Поставщик], [Услуга]

	END
	--endregion
	--**************************************************************************************************
	--region 3 История редактирования
	IF @p1 = 3
	BEGIN
		SELECT TOP (@count_row) SUBSTRING(u.Initials, 1, 25) AS 'Имя пользователя'
							  , o.name AS 'Виды работ'
							  , CONVERT(VARCHAR(12), op.done, 106) AS 'Дата'
							  , op.comp AS 'Компьютер'
							  , op.comments AS 'Комментарий'
		FROM dbo.Op_Log AS op 
			JOIN dbo.Operations AS o ON op.op_id = o.op_id
			LEFT JOIN dbo.Users AS u ON op.user_id = u.id
		WHERE op.Occ = @occ1
		ORDER BY op.done DESC
			   , op.id DESC
	END
	--endregion
	--**************************************************************************************************
	--region 4.0 История субсидий
	IF (@p1 = 4)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) fin_id AS 'id'
							  , dbo.Fun_NameFinPeriod(fin_id) AS 'Фин.период'
							  , CONVERT(VARCHAR(12), dateRaschet, 106) AS 'Дата расчета'
							  , CONVERT(VARCHAR(12), dateNazn, 106) AS 'Дата назн.'
							  , CONVERT(VARCHAR(12), DateEnd, 106) AS 'Дата оконч.'
							  , sumkomp AS 'Сумма комп.'
							  , sumkvart AS 'Сумма кварт.'
							  , sumnorm AS 'Сумма норм.'
							  , (sumnorm - sumkomp) AS 'Соц. платеж'
							  , Doxod AS 'Доход'
							  , metod AS 'Метод'
							  , kol_people AS 'Кол.чел.'
							  , realy_people AS 'Проживает'
							  , transfer_bank AS 'в банк'
							  , SUBSTRING(dbo.Fun_InitialsPeople(owner_id), 1, 20) AS 'Получатель'
		FROM dbo.View_compensac 
		WHERE Occ = @occ1
		ORDER BY fin_id DESC
	END
	--endregion
	--region 4.1 История субсидий по услугам
	IF (@p1 = 4)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			dbo.Fun_NameFinPeriod(fin_id) AS 'Фин.период'
		  , SUBSTRING(s.name, 1, 20) AS 'услуга'
		  , CAST(tarif AS DECIMAL(9, 2)) AS 'тариф'
		  , CAST(subsid_norma AS DECIMAL(9, 2)) AS 'норма'
		  , CAST(value_socn AS DECIMAL(9, 2)) AS 'соц.норма'
		  , CAST(value_paid AS DECIMAL(9, 2)) AS 'начислено'
		  , CAST(value_subs AS DECIMAL(9, 2)) AS 'субсидия'
		FROM dbo.View_comp_serv AS cs 
			JOIN dbo.View_services_access AS s  ON cs.service_id = s.id
		WHERE Occ = @occ1
			AND cs.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 5.0 История платежей (показываем все)
	IF (@p1 = 5)
		AND (@p2 = 0)
	BEGIN
		--PRINT @Only_sup

		IF @Only_sup = CAST(1 AS BIT)
			SELECT TOP (@count_row) gb.StrMes AS 'Фин.период'
								, CONVERT(VARCHAR(12), pd.day, 106) AS 'Дата платежа'
								, CONVERT(VARCHAR(12), pd.date_edit, 106) AS 'Дата закрытия'
								, CAST(p.[Value] AS MONEY) AS 'Сумма'
								, CAST(p.PaymAccount_peny AS MONEY) AS 'Оплач.пени'
								, CAST((p.Value - COALESCE(p.PaymAccount_peny, 0)) AS MONEY) AS 'Оплата без пени'
								, CAST(p.commission AS MONEY) AS 'Комиссия'
								, SUBSTRING(sup.name, 1, 25) AS 'Поставщик'
								, b.short_name AS 'Банк'
								, pt.name AS 'Вид платежа'
								, CASE
									WHEN scan = 0 THEN 'ручной'
									--WHEN scan = 0 THEN 'сканером'
									ELSE bs.filenamedbf
								END AS 'Метод ввода'
								, p.occ_sup AS 'Лиц. в файле'
								, p.id AS 'id'
								, pd.id AS 'Код пачки'
								, p.paying_vozvrat AS 'Код возврата'
								, YEAR(gb.start_date) AS 'Год'
								, gb.start_date AS 'Период'
								, p.peny_save AS 'Оплата пени как в платеже'
								, p.paying_manual AS 'Ручн.изменение по услугам'
								, p.comment AS 'Комментарий'
								, u.Initials AS 'Пользователь'
								, CONCAT(pl.metod_ostatok,' (',dbo.FSTR(pl.ostatok,9,2),')') as metod_ostatok
								, pl.msg_log
			FROM dbo.Payings AS p 
				JOIN dbo.Paydoc_packs AS pd  ON p.pack_id = pd.id
				LEFT JOIN dbo.Paycoll_orgs AS po ON pd.source_id = po.id
				JOIN dbo.bank AS b  ON po.bank = b.id
				JOIN dbo.Paying_types AS pt  ON po.vid_paym = pt.id
				JOIN dbo.Global_values AS gb  ON pd.fin_id = gb.fin_id
				LEFT JOIN dbo.Suppliers_all AS sup ON p.sup_id = sup.id
				LEFT JOIN dbo.Bank_tbl_spisok AS bs  ON p.filedbf_id = bs.filedbf_id
				LEFT OUTER JOIN dbo.Users AS u  ON pd.user_edit = u.id
				LEFT JOIN dbo.Paying_log as pl  ON pl.paying_id=p.id
			WHERE p.Occ = @occ1
				AND p.forwarded = CAST(1 AS BIT)
				-- для ограничения доступа по старым периодам
				--AND pd.fin_id >= (
				--	SELECT COALESCE(MIN(fin_id), 0)
				--	FROM dbo.Occupation_Types_History AS VTA
				--	WHERE VTA.id = pd.tip_id
				--)
			ORDER BY pd.fin_id DESC
				   , pd.day DESC
				   , id DESC
			OPTION(RECOMPILE)
		ELSE -- Ограничение по поставщику
			SELECT TOP (@count_row) gb.StrMes AS 'Фин.период'
								  , CONVERT(VARCHAR(12), pd.day, 106) AS 'Дата платежа'
								  , CONVERT(VARCHAR(12), pd.date_edit, 106) AS 'Дата закрытия'
								  , CAST(p.[Value] AS MONEY) AS 'Сумма'
								  , CAST(p.PaymAccount_peny AS MONEY) AS 'Оплач.пени'
								  , CAST((p.Value - COALESCE(p.PaymAccount_peny, 0)) AS MONEY) AS 'Оплата без пени'
								  , CAST(p.commission AS MONEY) AS 'Комиссия'
								  , sup.name AS 'Поставщик'
								  , pd.id AS 'Код пачки'
								  , bnk.short_name AS 'Банк'
								  , pt.name AS 'Вид платежа'
								  , p.id AS 'id'	   			   
								  , CASE
										WHEN scan = 0 THEN 'ручной'
										--WHEN scan = 0 THEN 'сканером'
										--ELSE 'файл: ' + dbo.Fun_GetFileNamePaying(p.id)
										ELSE bs.filenamedbf
									END AS 'Метод ввода'
								  , p.occ_sup AS 'Лиц. в файле'
								  , YEAR(gb.start_date) AS 'Год'
								  , p.paying_vozvrat AS 'Код возврата'
								  , gb.start_date AS 'Период'
								  , p.peny_save AS 'Оплата пени как в платеже'
								  , p.paying_manual AS 'Ручн.изменение по услугам'
								  , p.comment AS 'Комментарий'
								  , u.Initials AS 'Пользователь'					  								  
								  , CONCAT(pl.metod_ostatok,' (',dbo.FSTR(pl.ostatok,9,2),')') as metod_ostatok
								  , pl.msg_log
			FROM dbo.Payings AS p
				JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
				LEFT JOIN dbo.Paycoll_orgs AS po ON pd.source_id = po.id
				JOIN dbo.Bank AS bnk ON po.bank=bnk.id
				JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
				JOIN dbo.Global_values AS gb ON pd.fin_id = gb.fin_id
				LEFT JOIN dbo.Suppliers_all AS sup  ON p.sup_id = sup.id
				LEFT JOIN dbo.Bank_tbl_spisok AS bs  ON p.filedbf_id = bs.filedbf_id
				LEFT OUTER JOIN dbo.Users AS u ON pd.user_edit = u.id
				LEFT JOIN dbo.Paying_log as pl  ON pl.paying_id=p.id
			WHERE p.Occ = @occ1
				AND p.forwarded = CAST(1 AS BIT)
			--AND sup_id = @Only_sup				
			ORDER BY pd.day DESC
				   , id DESC
			OPTION(RECOMPILE)
	END
	--endregion
	--region 5.1 История платежей (показываем раскидку по услугам)
	IF (@p1 = 5)
		AND (@p2 > 0)
	BEGIN
		SELECT --TOP(@coun_row)
			s.service_no AS '№'
		  , CONVERT(VARCHAR(12), pd.day, 106) AS 'Дата платежа'
		  , s.name AS 'Услуга'
		  , CAST(ps.[Value] AS MONEY) AS 'Сумма'
		  , CAST(ps.PaymAccount_peny AS MONEY) AS 'из них пени'
		  , CAST((ps.Value - COALESCE(ps.PaymAccount_peny, 0)) AS MONEY) AS 'Оплата без пени'
		  , ps.commission AS 'Комиссия'
		  , s.is_peny AS 'Возможен расч.пени'
		  , vs.service_name_kvit AS 'Услуга в квитанции'
		FROM dbo.Paying_serv AS ps 
			JOIN dbo.View_services_access AS s ON 
				ps.service_id = s.id
			JOIN dbo.Payings AS p ON 
				p.id = ps.paying_id
			JOIN dbo.Paydoc_packs AS pd ON 
				p.pack_id = pd.id
			JOIN dbo.Occupations o ON 
				ps.Occ = o.Occ
			JOIN dbo.Flats f ON 
				o.flat_id = f.id
			LEFT JOIN dbo.View_services_kvit vs ON 
				ps.service_id = vs.service_id
				AND pd.tip_id = vs.tip_id
				AND f.bldn_id = vs.build_id
		WHERE p.Occ = @occ1
			AND p.id = @p2
		UNION ALL
		SELECT 1000
			 , NULL
			 , 'Итого:'
			 , CAST(SUM(ps.Value) AS MONEY)
			 , CAST(SUM(ps.PaymAccount_peny) AS MONEY)
			 , CAST(SUM(ps.Value - COALESCE(ps.PaymAccount_peny, 0)) AS MONEY)
			 , CAST(SUM(COALESCE(ps.commission, 0)) AS MONEY)
			 , CAST(0 AS BIT)
			 , NULL
		FROM dbo.Paying_serv AS ps
		WHERE ps.Occ = @occ1
			AND ps.paying_id = @p2
		ORDER BY 1 --s.service_no

	END
	--endregion
	--**************************************************************************************************
	--region 6 История льгот
	IF @p1 = 6
	BEGIN
		DECLARE @TableTemp TABLE (
			  id1 INT
		)
		DECLARE @owner_id1 INT

		DECLARE curs CURSOR LOCAL FOR
			SELECT id
			FROM dbo.People 
			WHERE Occ = @occ1
		OPEN curs
		FETCH NEXT FROM curs INTO @owner_id1

		WHILE (@@fetch_status = 0)
		BEGIN
			INSERT INTO @TableTemp
			SELECT id1
			FROM dbo.Fun_SpisokLgotaActive(@owner_id1)

			FETCH NEXT FROM curs INTO @owner_id1
		END

		CLOSE curs
		DEALLOCATE curs


		SELECT TOP (@count_row)
			--SUBSTRING(dbo.Fun_InitialsPeople(p.Id), 1, 25) AS 'Ф.И.О.'
			SUBSTRING(p.Initials_people, 1, 25) AS 'Ф.И.О.'
		  , SUBSTRING(dg.name, 1, 25) AS 'Льгота'
		  , CAST(ow.dscgroup_id AS CHAR(5)) AS 'Код'
		  , SUBSTRING(ow.doc, 1, 30) AS 'Документ'
		  , RTRIM(doc_seria) AS 'Серия'
		  , RTRIM(doc_no) AS 'Номер'
		  , CONVERT(VARCHAR(12), ow.issued, 106) AS 'Дата выдачи'
		  , CONVERT(VARCHAR(12), ow.expire_date, 106) AS 'Действ. по'
		  , CONVERT(VARCHAR(12), ow.DelDateLgota, 106) AS 'Дата удал.'
		  , dbo.Fun_GetFIOUser(ow.user_id) AS 'Пользователь'
		FROM dbo.Dsc_owners AS ow 
			JOIN dbo.Dsc_groups AS dg ON 
				ow.dscgroup_id = dg.id
			JOIN dbo.VPeople AS p ON 
				ow.owner_id = p.id
		WHERE p.Occ = @occ1
			AND NOT EXISTS (
				SELECT 1
				FROM @TableTemp
				WHERE id1 = ow.id
			)
	END
	--endregion
	--**************************************************************************************************
	--region 7 История лиц. счета
	IF @p1 = 7
	BEGIN
		SELECT TOP (@count_row) gb.StrMes AS 'Фин.период'
							  , CONVERT(VARCHAR(7), gb.start_date, 126) AS 'Период'
							  , CAST(oh.SALDO AS MONEY) AS 'вх.сальдо'
							  , CAST(oh.[Value] AS MONEY) AS 'начисленно'
							  , CAST(oh.Discount AS MONEY) AS 'льгота'
							  , CAST(oh.Added AS MONEY) AS 'перерасчёт'
							  , CAST((oh.Paid + oh.Paid_minus) AS MONEY) AS 'ит.начисл.'
							  , CAST(oh.Penalty_old AS MONEY) AS 'пени стар.'
							  , CAST(oh.Penalty_old_new AS MONEY) AS 'пени стар.изм'
							  , CAST(oh.Penalty_value AS MONEY) AS 'пени'
							  , CAST(oh.Penalty_added AS MONEY) AS 'пени разовые'
							  , CAST(oh.Penalty_itog AS MONEY) AS 'пени итог'
							  , CAST(oh.Whole_payment AS MONEY) AS 'к оплате'
							  , CAST(oh.PaymAccount AS MONEY) AS 'оплатил'
							  , CAST(oh.PaymAccount_peny AS MONEY) AS 'из них пени'
							  , CAST((oh.PaymAccount - oh.PaymAccount_peny) AS MONEY) AS 'оплата без пени'
							  , CAST(oh.Debt AS MONEY) AS 'кон.сальдо'
							  , CAST(oh.roomtype_id AS CHAR(6)) AS 'тип'
							  , CAST(oh.proptype_id AS CHAR(6)) AS 'прив'
							  , CAST(oh.status_id AS CHAR(6)) AS 'статус'
							  , CASE socnaim
									WHEN CAST(1 AS BIT) THEN CONVERT(CHAR(3), 'да')
									ELSE CONVERT(CHAR(3), 'нет')
								END AS 'договор'
							  , CAST(total_sq AS DECIMAL(9, 2)) AS 'площадь'
							  , oh.build_id AS 'код дома'
							  , oh.flat_id AS 'код кварт'
							  , oh.fin_id AS 'код фин.периода'
							  , YEAR(gb.start_date) AS 'Год'
							  , MONTH(gb.start_date) AS 'Месяц'
							  , oh.jeu AS 'участок'
							  , ot.name AS 'тип фонда'
							  , oh.comments AS 'коммент.'
							  , oh.Penalty_calc AS 'расчёт пени'
							  , oh.id_jku_gis AS 'УИ ГИС ЖКХ'
							  , oh.comments_print AS 'коммент. в квитанции'
							  , oh.date_start AS 'Дата начала'
							  , oh.date_end AS 'Дата окончания'
		FROM dbo.View_occ_all oh    --dbo.OCC_HISTORY AS oh 
			JOIN dbo.VOcc_types_all_lite AS ot ON oh.tip_id = ot.id
				AND oh.fin_id = ot.fin_id
			JOIN dbo.Global_values AS gb ON oh.fin_id = gb.fin_id			
		WHERE oh.Occ = CASE
                           WHEN @Only_sup = CAST(1 AS BIT) THEN 0
                           ELSE @occ1
            END
		ORDER BY oh.fin_id DESC
	END
	--endregion
	--**************************************************************************************************
	--region 8 История разовых
	IF (@p1 = 8)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) ap.fin_id AS 'id'
							  , dbo.Fun_NameFinPeriodDate(MIN(ap.start_date)) AS 'Фин.период'
							  , CAST(SUM(ap.Value) AS MONEY) AS 'Сумма'
		FROM dbo.View_added AS ap
		WHERE ap.Occ = @occ1
		GROUP BY ap.fin_id
		ORDER BY ap.fin_id DESC
	END

	IF (@p1 = 8)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			cp.StrFinPeriod AS 'Фин.период'
		  , s.short_name AS 'Услуга'
		  , t.name AS 'Тип'
		  , Value AS 'Сумма'
		  , doc AS 'Документ'
		  , data1 AS 'День1'
		  , data2 AS 'День2'
		  , [Hours] AS 'Часы'
		  , sec.name AS 'Виновник1'
		  , sup.name AS 'Виновник2'
		  , doc_no AS 'Ном.док.'
		  , doc_date AS 'Дата_док.'
		  , u.Initials AS 'Пользователь'
		 -- , CASE
			--	WHEN ap.add_type = 6 THEN (
			--			SELECT dbo.Fun_InitialsPeople(p.id)
			--			FROM dbo.People AS p 
			--				JOIN dbo.Dsc_owners AS do ON p.id = do.owner_id
			--			WHERE do.id = ap.dsc_owner_id
			--		)
			--	ELSE (
			--			SELECT dbo.Fun_InitialsPeople(p.id)
			--			FROM dbo.People AS p 
			--			WHERE p.id = ap.dsc_owner_id
			--		)
			--END 
		  , '' AS 'Получатель'
		  , ap.kod AS 'Код'
		  , ap.kol AS 'Кол-во'
		  , ap.comments
		  , sa.name AS 'Поставщик'
		FROM dbo.View_added AS ap 
			LEFT OUTER JOIN Sector AS sec ON Vin1 = sec.id
			LEFT OUTER JOIN View_suppliers AS sup ON Vin2 = sup.id
			JOIN dbo.View_services_access AS s ON ap.service_id = s.id
			JOIN dbo.Added_Types AS t ON ap.add_type = t.id
			LEFT JOIN Suppliers_all sa ON ap.sup_id = sa.id
			JOIN Calendar_period cp ON cp.fin_id = ap.fin_id
			LEFT JOIN Users AS u ON u.id = ap.user_edit
		WHERE ap.Occ = @occ1
			AND ap.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 10 Изменение пени 
	IF @p1 = 10
	BEGIN
		SELECT --TOP (@count_row) 
			p.Occ AS 'Лицевой'
			, CONVERT(VARCHAR(12), p.data, 106) AS 'Дата'
			, u.Initials AS 'Пользователь'
			, p.sum_old AS 'Сумма стар.'
			, p.sum_new AS 'Сумма нов.'
			, p.comments AS 'Комментарий'
			, cp.StrFinPeriod AS 'Фин.период'
		FROM dbo.Penalty_log AS p
			JOIN dbo.Peny_all AS pa ON pa.occ=p.occ AND pa.fin_id=p.fin_id
			JOIN dbo.Calendar_period cp ON cp.fin_id = p.fin_id
			LEFT JOIN dbo.Users AS u ON p.[user_id] = u.id			
		WHERE (pa.Occ1 = @occ1) OR (pa.occ=@occ1)
		ORDER BY data DESC
		--OPTION(RECOMPILE, MAXDOP 1)
	END
	--endregion
	--**************************************************************************************************
	--region 11 История режимов потребления
	IF (@p1 = 11)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) o.fin_id AS 'id'
							  , dbo.Fun_NameFinPeriodDate(MIN(o.start_date))AS 'Фин.период'
		FROM dbo.View_occ_all AS o 
		WHERE o.Occ = @occ1
		GROUP BY o.fin_id
		ORDER BY o.fin_id DESC
	END

	IF (@p1 = 11)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			cp.StrFinPeriod AS 'Фин.период'
		  , s.name AS 'Услуга'
		  , cm.name AS 'Режим'
		  , sp.name AS 'Поставщик'
		  , Koef AS 'Коэф-т'
		  , subsid_only AS 'Внеш.усл.'
		  , CASE
				WHEN ch.is_counter = 1 THEN 'Внеш.'
				WHEN ch.is_counter = 2 THEN 'Внутрен.'
				ELSE ''
			END AS 'Счет.'
		  , ch.account_one AS 'Отд.квит.'
		FROM dbo.View_consmodes_all AS ch 
			JOIN dbo.Cons_modes AS cm ON ch.mode_id = cm.id
			LEFT JOIN dbo.View_suppliers AS sp ON ch.source_id = sp.id
			JOIN dbo.View_services_access AS s ON ch.service_id = s.id
			JOIN Calendar_period cp ON cp.fin_id = ch.fin_id
		WHERE Occ = @occ1
			AND ch.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 12.0 История начислений по счетчикам.
	-- Суммарные значения по финансовым периодам
	IF (@p1 = 12)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) p.fin_id AS 'id'
							  , MIN(cp.StrFinPeriod) AS 'Фин.период'
							  , CAST(SUM(p.SALDO) AS MONEY) AS 'Вх.Сальдо'
							  , CAST(SUM(p.Value) AS MONEY) AS 'Начислено'
							  , CAST(SUM(p.Discount) AS MONEY) AS 'Льгота'
							  , CAST(SUM(p.Compens) AS MONEY) AS 'Субсидия'
							  , CAST(SUM(p.Added) AS MONEY) AS 'Перерасчет'
							  , CAST(SUM(p.Paid) AS MONEY) AS 'Итого начисл.'
							  , CAST(SUM(p.PaymAccount) AS MONEY) AS 'Оплатил'
							  , CAST(SUM(p.PaymAccount_peny) AS MONEY) AS 'из них пени'
							  , CAST(SUM(p.Debt) AS MONEY) AS 'Кон. сальдо'
		FROM dbo.View_paym_counter AS p 
			JOIN dbo.VOcc_history AS o ON p.Occ = o.Occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_services_access AS s ON p.service_id = s.id
			JOIN Calendar_period cp ON cp.fin_id = p.fin_id
		WHERE p.Occ = @occ1
		GROUP BY p.fin_id
		ORDER BY p.fin_id DESC
	END
	--endregion
	--region 12.1 История начислений по счетчикам.  Значения по заданному фин.периоду
	IF (@p1 = 12)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			s.service_no AS 'Код'
		  , cp.StrFinPeriod AS 'Фин.период'
		  , SUBSTRING(s.name, 1, 20) AS 'Услуга'
		  , CAST(SALDO AS MONEY) AS 'Вх.Сальдо'
		  , CAST(Value AS MONEY) AS 'Начислено'
		  , CAST(Discount AS MONEY) AS 'Льгота'
		  , CAST(Compens AS MONEY) AS 'Субсидия'
		  , CAST(Added AS MONEY) AS 'Перерасчет'
		  , CAST(Paid AS MONEY) AS 'Ит.начисл.'
		  , CAST(PaymAccount AS MONEY) AS 'Оплатил'
		  , CAST(PaymAccount_peny AS MONEY) AS 'из них пени'
		  , CAST(p.Debt AS MONEY) AS 'Кон. сальдо'
		  , subsid_only AS 'Внеш.услуга'
		FROM dbo.View_paym_counter AS p
			JOIN dbo.View_services_access AS s ON 
				p.service_id = s.id
			JOIN dbo.Calendar_period cp ON 
				cp.fin_id = p.fin_id
		WHERE p.Occ = @occ1
			AND p.fin_id = @p2
		UNION ALL
		SELECT 1000
			 , 'Итого:'
			 , NULL
			 , CONVERT(MONEY, SUM(SALDO))
			 , CONVERT(MONEY, SUM(Value))
			 , CONVERT(MONEY, SUM(Discount))
			 , CONVERT(MONEY, SUM(Compens))
			 , CONVERT(MONEY, SUM(Added))
			 , CONVERT(MONEY, SUM(Paid))
			 , CONVERT(MONEY, SUM(PaymAccount))
			 , CONVERT(MONEY, SUM(PaymAccount_peny))
			 , CONVERT(MONEY, SUM(p.Debt))
			 , NULL
		FROM dbo.View_paym_counter AS p 
			JOIN dbo.View_services_access AS s ON 
				p.service_id = s.id
		WHERE p.Occ = @occ1
			AND p.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 13 История разовых по счетчикам
	IF (@p1 = 13)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) ap.fin_id AS 'id'
							  , dbo.Fun_NameFinPeriod(ap.fin_id) AS 'Фин.период'
							  , SUM(Value) AS 'Сумма'
		FROM dbo.Added_Counters_All AS ap 
		WHERE ap.Occ = @occ1
		GROUP BY ap.fin_id
		ORDER BY ap.fin_id DESC
	END

	IF (@p1 = 13)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			dbo.Fun_NameFinPeriod(ap.fin_id) AS 'Фин.период'
		  , SUBSTRING(s.name, 1, 20) AS 'Услуга'
		  , t.name AS 'Тип'
		  , Value AS 'Сумма'
		  , doc AS 'Документ'
		  , data1 AS 'День1'
		  , data2 AS 'День2'
		  , sec.name AS 'Виновник1'
		  , sup.name AS 'Виновник2'
		  , doc_no AS 'Ном.док.'
		  , doc_date AS 'Дата_док.'
		FROM dbo.Added_Counters_All AS ap 
			JOIN dbo.View_services_access AS s ON 
				ap.service_id = s.id
			JOIN dbo.Added_Types AS t ON 
				ap.add_type = t.id
			LEFT OUTER JOIN dbo.Sector AS sec ON 
				Vin1 = sec.id
			LEFT OUTER JOIN dbo.View_suppliers AS sup ON 
				Vin2 = sup.id
		WHERE ap.Occ = @occ1
			AND ap.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 14 История по человеку
	IF (@p1 = 14)
		AND (@p2 = 0)
		SELECT TOP (@count_row) ph.Occ AS 'Лицевой'
							  , cp.StrFinPeriod AS 'Фин_период'
							  , owner_id AS 'Код_гражданина'
								--,lgota_id AS 'Льгота'
							  , st.name AS 'Социальный_статус'
							  , ps.name AS 'Статус_регистрации'
							  , ph.DateEnd AS 'Дата_окончания'
							  , ph.fin_id
		--, lgota_kod
		FROM dbo.People_history AS ph 
			JOIN dbo.Status AS st ON 
				ph.status_id = st.id
			JOIN dbo.Person_statuses AS ps ON 
				ph.Status2_id = ps.id
			JOIN dbo.VOcc_history AS o ON 
				ph.Occ = o.Occ
				AND ph.fin_id = o.fin_id
			JOIN Calendar_period cp ON 
				cp.fin_id = ph.fin_id
		WHERE ph.owner_id = @occ1  -- в @occ1 будет код гражданина
		ORDER BY ph.fin_id DESC
	--endregion
	--**************************************************************************************************
	--region 15 История начислений по услугам по лицевому
	IF (@p1 = 15)
		SELECT s.service_no AS 'Код'
			 , dbo.Fun_NameFinPeriodDate(o.start_date) AS 'Фин.период'
			 , CASE
                   WHEN p.sup_id > 0 THEN p.occ_sup_paym
                   ELSE p.Occ
				END AS 'Лицевой'
			 , SUBSTRING(s.name, 1, 50) AS 'Услуга'
			 , CAST(p.SALDO AS MONEY) AS 'Вх.Сальдо'
			 , CAST(p.Value AS MONEY) AS 'Начислено'
			 , CAST(p.Discount AS MONEY) AS 'Льгота'
			 , CAST(p.Compens AS MONEY) AS 'Субсидия'
			 , CAST(p.Added AS MONEY) AS 'Перерасчет'
			 , CAST(p.Paid AS MONEY) AS 'Ит.начисл.'
			 , CAST(p.PaymAccount AS MONEY) AS 'Оплатил'
			 , CAST(p.PaymAccount_peny AS MONEY) AS 'из них пени'
			 , CAST((p.PaymAccount - p.PaymAccount_peny) AS MONEY) AS 'Оплата без пени'
			 , CAST(p.Debt AS MONEY) AS 'Кон. сальдо'
			 , p.subsid_only AS 'Внеш.услуга'
			 , p.tarif AS 'Тариф'
			 , p.kol AS 'Кол-во'
			 , p.kol_added AS 'Кол. разовых'
			 , COALESCE(p.kol_added, 0) AS 'Объем разовых'
			 , YEAR(o.start_date) AS 'Год'
			 , DATEPART(qq, o.start_date) AS 'Квартал'
			 , MONTH(o.start_date) AS 'Месяц'
			 , p.fin_id AS 'id'
			 , met1.name AS 'Метод'
			 , p.account_one AS 'Отд.квит.'
			 , o.start_date AS 'Период'
			 , kol_norma AS 'Кол-во норма'
			 , U.short_id AS 'Ед.изм.'
			 , s.is_build AS 'ОДН'
			 , COALESCE(p.Koef, 1) AS 'Коэф'
			 , p.Penalty_old AS 'Пени прошл'
			 , p.Penalty_old AS 'Пени прошл изм'
			 , p.penalty_serv AS 'Пени новое'
			 , s.is_peny AS 'Признак расч.пени'
			 , sa.name AS 'Поставщик'
			 , CASE
				   WHEN p.is_counter > 0 THEN 1
				   ELSE 0
			   END AS 'ИПУ'
			 , o.id_jku_gis AS 'УИ ГИС ЖКХ'
			 , o.nom_kvr AS '№ кв'
			 , sa.id AS sup_id  -- нужно для возвратов в Картотеке
			 , p.service_id AS service_id  -- нужно для возвратов в Картотеке
			 , p.date_start AS 'Дата начала'
			 , p.date_end AS 'Дата окончания'
			 , p.koef_day AS 'Коэф_Дней'
		FROM dbo.Paym_history AS p 
			JOIN dbo.View_occ_all AS o -- для ограничения доступа
				ON p.Occ = o.Occ
				AND p.fin_id = o.fin_id
			JOIN dbo.View_services_access AS s ON 
				p.service_id = s.id  -- для ограничения доступа по услугам -- возможно надо заменить
			LEFT JOIN dbo.Units U ON 
				p.unit_id = U.id
			LEFT JOIN dbo.Suppliers_all AS sa ON 
				p.sup_id = sa.id
			LEFT JOIN dbo.view_metod as met1 ON 
				p.metod_old=met1.id
		WHERE (p.Occ = @occ1)
		ORDER BY o.start_date DESC
			   , s.service_no
	--endregion
	--**************************************************************************************************
	--region 16 История по поставщикам 
	IF (@p1 = 16)
		SELECT TOP (@count_row) gb.StrMes AS 'Фин.период'
							  , oh.occ_sup AS 'Лиц. Поставщика'
							  , oh.SALDO AS 'вх.сальдо'
							  , oh.[Value] AS 'начисленно'
							  , oh.Added AS 'перерасчёт'
							  , oh.Paid AS 'пост.начисл.'
							  , oh.Penalty_old AS 'пени стар.'
							  , oh.Penalty_old_new AS 'пени стар.изм'
							  , oh.Penalty_value AS 'пени'
							  , oh.Penalty_added AS 'пени разовые'
							  , (oh.debt_peny) AS 'пени итог'
							  , oh.Whole_payment AS 'к оплате'
							  , oh.PaymAccount AS 'оплатил'
							  , oh.PaymAccount_peny AS 'из них пени'
							  , (oh.PaymAccount - oh.PaymAccount_peny) AS 'Оплата без пени'
							  , oh.Debt AS 'кон.сальдо'
							  , YEAR(gb.start_date) AS 'Год'
							  , sup.name AS 'Поставщик'
							  , oh.dog_int AS 'Код договора'
							  , oh.sup_id AS 'Код поставщика'
							  , oh.rasschet AS 'Расч/счёт'
							  , oh.cessia_dolg_mes_new AS 'Цессия мес.'
							  , oh.id_jku_gis AS 'УИ ГИС ЖКХ'
							  , CASE
                                    WHEN oh.Penalty_old_edit = 1 THEN 'Да'
                                    ELSE 'Нет'
            END AS 'Признак ручн.изм. пени'
		                      , oh.occ_sup_uid AS occ_sup_uid
		FROM dbo.VOcc_Suppliers AS oh 
			JOIN dbo.Global_values AS gb ON 
				oh.fin_id = gb.fin_id
			JOIN dbo.Suppliers_all AS sup ON 
				oh.sup_id = sup.id
			JOIN dbo.View_occ_all AS o ON 
				oh.Occ = o.Occ
				AND oh.fin_id = o.fin_id
		WHERE oh.Occ = @occ1
		ORDER BY oh.fin_id DESC
	--endregion
	--**************************************************************************************************
	--region 17 История начислений по Общедомовым приборам учёта
	IF (@p1 = 17)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) POB.fin_id AS 'id'
							  , dbo.Fun_NameFinPeriodDate(MIN(o.start_date)) AS 'Фин.период'
							  , CAST(SUM(POB.Value) AS MONEY) AS 'Сумма'
		FROM dbo.Paym_occ_build AS POB 
			JOIN dbo.View_occ_all_lite AS o ON 
				POB.Occ = o.Occ
				AND POB.fin_id = o.fin_id
			JOIN dbo.View_services_access AS s ON 
				POB.service_id = s.id
		WHERE POB.Occ = @occ1
		GROUP BY POB.fin_id
		ORDER BY POB.fin_id DESC
	END

	IF (@p1 = 17)
		AND (@p2 <> 0)
	BEGIN
		SELECT --TOP(@coun_row)
			cp.StrFinPeriod AS 'Фин.период'
		  , s.short_name AS 'Услуга'
		  , POB.kol AS 'Количество'
		  , CAST(Value AS MONEY) AS 'Сумма'
		  , CAST(tarif AS DECIMAL(9, 2)) AS 'Тариф'
		  , POB.comments AS 'Документ'
		  , unit_id AS 'Ед.изм.'
		  , procedura AS 'Процедура'
		  , data AS 'Дата создания'
		  , u.Initials AS 'Пользователь'
		  , POB.kol_add AS 'Кол.разница'
		  , POB.service_id
		FROM dbo.Paym_occ_build AS POB
			JOIN dbo.View_services_access AS s ON 
				POB.service_id = s.id
			JOIN Calendar_period cp ON 
				cp.fin_id = POB.fin_id
			LEFT JOIN dbo.Users AS u ON 
				u.login = POB.user_login
		WHERE POB.Occ = @occ1
			AND POB.fin_id = @p2
		ORDER BY s.service_no
	END
	--endregion
	--**************************************************************************************************
	--region 18 История по людям
	IF (@p1 = 18)
		AND (@p2 = 0)
	BEGIN
		SELECT SUBSTRING(p.Last_name, 1, 20) AS 'Фамилия'
			 , SUBSTRING(p.First_name, 1, 20) AS 'Имя'
			 , SUBSTRING(p.Second_name, 1, 20) AS 'Отчество'
			 , CONVERT(VARCHAR(12), p.Birthdate, 106) AS 'День рожд.'
			 , CONVERT(VARCHAR(12), p.DateReg, 106) AS 'Дата регистр.'
			 , CONVERT(VARCHAR(12), p.DateDel, 106) AS 'Дата выписки'
			 , CONVERT(VARCHAR(12), p.DateEnd, 106) AS 'Дата оконч.рег.'
			 , fam.name AS 'Родств.отношения'
			 , ps.name AS 'Последний статус регистрации'
			   --,dbo.Fun_GetBetweenDateYear(p.birthdate, current_timestamp) AS 'Возраст'
			 , CASE
				   WHEN Del = CAST(1 AS BIT) THEN SUBSTRING(re.name, 1, 30)
				   ELSE NULL
			   END AS 'Причина выписки'
			 , CONVERT(VARCHAR(12), p.DateDeath, 106) AS 'Дата смерти'
			 , SUBSTRING(CONCAT(p2.KraiBirth , ' ' , p2.RaionBirth , ' ' , p2.TownBirth , ' ' , p2.VillageBirth), 1, 50) AS 'Место рождения'
			 , p.id AS 'Код'
			 , p.Initials_people AS 'ФИО'
		     , p.people_uid AS people_uid
		FROM dbo.VPeople AS p
			JOIN dbo.Person_statuses AS ps ON 
				p.Status2_id = ps.id
			LEFT JOIN dbo.Reason_extract AS re ON 
				COALESCE(p.Reason_extract, 0) = re.id
			LEFT JOIN dbo.People_2 AS p2 ON 
				p.id = p2.owner_id
			LEFT OUTER JOIN dbo.Fam_relations AS fam ON 
				p.Fam_id = fam.id
		WHERE p.occ = @occ1
			AND EXISTS(
				SELECT 1
				FROM dbo.People_history ph
				WHERE ph.owner_id = p.id
			)
		ORDER BY p.Del
			   , p.Birthdate
			   , p.DateDel DESC
	END
	--endregion
	--**************************************************************************************************
	--region 19 История приборов учёта
	IF (@p1 = 19)
		AND (@p2 = 0)
	BEGIN
		SELECT c.id AS 'Код'
			 , s.name AS 'Услуга'
			 , c.serial_number AS 'Серийный номер'
			 , c.type AS 'Тип'
			 , c.unit_id AS 'Ед.измер.'
			 , CAST(c.count_value AS INT) AS 'Начальное показание'
			 , c.date_create AS 'Дата приёмки'
			 , CAST(c.CountValue_del AS INT) AS 'Показание при закрытии'
			 , c.date_del AS 'Дата закрытия'
			 , c.PeriodCheck AS 'Период поверки'
			 , c.comments AS 'Комментарий'
			 , CASE
                   WHEN c.date_del IS NULL THEN 'Работает'
                   ELSE 'Закрыт'
            END AS 'Состояние'
			 , o.address AS 'Адрес'
			 , c.date_edit AS 'Дата редакт.'
			 , u.Initials AS 'Пользователь'
			 , COALESCE(cm.name, 'Текущий') AS 'Режим'
			 , c.id_pu_gis AS 'Код в ГИС ЖКХ'
			 , c.PeriodLastCheck AS 'Дата посл.поверки'
			 , c.PeriodInterval AS 'Межповерочный интервал'
		     , CAST(c.counter_uid AS VARCHAR(36)) AS counter_uid
		FROM dbo.Counters AS c
			JOIN dbo.Flats f ON 
				c.flat_id = f.id
			JOIN dbo.Occupations o ON 
				f.id = o.flat_id
			JOIN dbo.View_services_access AS s ON 
				c.service_id = s.id
			LEFT JOIN Users u ON 
				c.user_edit = u.id
			LEFT JOIN dbo.Cons_modes AS cm ON 
				c.mode_id = cm.id
				AND c.service_id = cm.service_id
		WHERE o.Occ = @occ1
		ORDER BY c.date_del
			   , c.service_id
	END
	--endregion

	--**************************************************************************************************
	--region 20 История Итогов по лицевым счетам 
	IF (@p1 = 20)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) YEAR(gb.start_date) AS 'Год'
							  , gb.StrMes AS 'Фин.период'
							  , T.Поставщик
							  , T.Лицевой
							  , T.[вх.сальдо]
							  , T.начисленно
								--,T.льгота
							  , T.перерасчёт
							  , T.[ит.начисл.]
							  , T.оплатил
							  , T.[из них пени]
							  , T.[оплата без пени]
							  , T.[кон.сальдо]
							  , T.[пени стар.]
							  , T.[пени стар.изм]
							  , T.[пени]
							  , T.[пени разовые]
							  , T.[пени итог]
							  , T.[к оплате]
							  , T.[УИ ГИС ЖКХ]
							  , CAST(roomtype_id AS CHAR(6))    AS 'тип'
							  , CAST(proptype_id AS CHAR(6))    AS 'прив'
							  , CAST(status_id AS CHAR(6))      AS 'статус'
							  , CAST(total_sq AS DECIMAL(9, 2)) AS 'площадь'
							  , F.bldn_id                       AS 'код дома'
							  , F.id                            AS 'код квартиры'
							  , gb.fin_id                       AS 'код периода'
							  , ot.name                         AS 'тип фонда'
							  , CAST(CASE WHEN socnaim = 1 THEN 'да' ELSE 'нет' END AS CHAR(3))AS 'договор'
		FROM (
			SELECT 'Нет' AS 'Поставщик'
				 , oh.Occ AS 'Лицевой'
				 , CAST(SALDO AS MONEY) AS 'вх.сальдо'
				 , CAST(oh.Value AS MONEY) AS 'начисленно'
				 , CAST(oh.Discount AS MONEY) AS 'льгота'
				 , CAST(oh.Added AS MONEY) AS 'перерасчёт'
				 , CAST((oh.Paid + oh.Paid_minus) AS MONEY) AS 'ит.начисл.'
				 , CAST(oh.Penalty_old AS MONEY) AS 'пени стар.'
				 , CAST(oh.Penalty_old_new AS MONEY) AS 'пени стар.изм'
				 , CAST(oh.Penalty_value AS MONEY) AS 'пени'
				 , CAST(oh.Penalty_added AS MONEY) AS 'пени разовые'
				 , CAST(oh.Penalty_itog AS MONEY) AS 'пени итог'
				 , CAST(oh.Whole_payment AS MONEY) AS 'к оплате'
				 , CAST(oh.PaymAccount AS MONEY) AS 'оплатил'
				 , CAST(oh.PaymAccount_peny AS MONEY) AS 'из них пени'
				 , CAST((oh.PaymAccount - oh.PaymAccount_peny) AS MONEY) AS 'оплата без пени'
				 , CAST(oh.Debt AS MONEY) AS 'кон.сальдо'
				 , oh.id_jku_gis AS 'УИ ГИС ЖКХ'
				 , oh.fin_id
				 , oh.Occ
			FROM dbo.View_occ_all oh
			WHERE oh.Occ = CASE
                               WHEN @Only_sup = CAST(1 AS BIT) THEN 0
                               ELSE @occ1
                END

			UNION ALL

			SELECT sup.name AS 'Поставщик'
				 , oh.occ_sup AS 'Лицевой'
				 , oh.SALDO AS 'вх.сальдо'
				 , oh.[Value] AS 'начисленно'
				 , 0 AS 'льгота'
				 , oh.Added AS 'перерасчёт'
				 , oh.Paid AS 'пост.начисл.'
				 , oh.Penalty_old AS 'пени стар.'
				 , oh.Penalty_old_new AS 'пени стар.изм'
				 , oh.Penalty_value AS 'пени'
				 , oh.Penalty_added AS 'пени разовые'
				 , oh.debt_peny AS 'пени итог'
				 , oh.Whole_payment AS 'к оплате'
				 , oh.PaymAccount AS 'оплатил'
				 , oh.PaymAccount_peny AS 'из них пени'
				 , (oh.PaymAccount - oh.PaymAccount_peny) AS 'Оплата без пени'
				 , oh.Debt AS 'кон.сальдо'
				 , oh.id_jku_gis AS 'УИ ГИС ЖКХ'
				 , oh.fin_id
				 , oh.Occ
			FROM dbo.VOcc_Suppliers AS oh
				JOIN dbo.Global_values AS gb ON 
					oh.fin_id = gb.fin_id
				JOIN dbo.Suppliers_all AS sup ON 
					oh.sup_id = sup.id
			WHERE oh.Occ = @occ1
		) AS T
			JOIN dbo.View_occ_all_lite AS o ON T.Occ = o.Occ
				AND T.fin_id = o.fin_id
			JOIN dbo.Flats AS F ON 
				o.flat_id = F.id
			JOIN dbo.Global_values AS gb ON 
				T.fin_id = gb.fin_id
			JOIN dbo.VOcc_types_all_lite AS ot ON 
				o.tip_id = ot.id
				AND o.fin_id = ot.fin_id
		ORDER BY gb.fin_id DESC
			   , T.Лицевой

	END
	--endregion

	--region 21 История платежей по чекам
	IF (@p1 = 21)
		AND (@p2 = 0)
	BEGIN
		SELECT TOP (@count_row) gb.StrMes AS 'Фин.период'
							  , CONVERT(VARCHAR(12), pd.day, 106) AS 'Дата платежа'
							  , CONVERT(VARCHAR(12), pd.date_edit, 106) AS 'Дата закрытия'
							  , CAST(p.[Value] AS MONEY) AS 'Сумма'
							  , CAST(p.PaymAccount_peny AS MONEY) AS 'Оплач.пени'
							  , CAST((p.Value - COALESCE(p.PaymAccount_peny, 0)) AS MONEY) AS 'Оплата без пени'
							  , CAST(p.commission AS MONEY) AS 'Комиссия'
							  , b.short_name AS 'Банк'
							  , p.occ_sup AS 'Лиц. в файле'
							  , p.id AS 'id'
							  , (
									SELECT SUM(pc.value_cash) AS value_cash
									FROM dbo.Paying_cash pc
									WHERE (pc.paying_id = p.id)
								) AS 'Раскидано в чеке'
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs AS pd ON 
				p.pack_id = pd.id
			LEFT JOIN dbo.Paycoll_orgs AS po ON 
				pd.source_id = po.id
			JOIN dbo.bank AS b ON 
				po.bank = b.id
			JOIN dbo.Global_values AS gb ON 
				pd.fin_id = gb.fin_id
		WHERE p.Occ = @occ1
			AND p.forwarded = CAST(1 AS BIT)
			-- для ограничения доступа по старым периодам
			AND pd.fin_id >= 156
		ORDER BY pd.fin_id DESC
			   , pd.day DESC
			   , id DESC
	END
	IF (@p1 = 21)
		AND (@p2 <> 0)
	BEGIN
		SELECT p.Occ AS 'Лицевой'
			 , pc.service_name AS 'Услуга'
			 , pc.value_cash AS 'Оплата'
		FROM dbo.Paying_cash pc 
		JOIN dbo.Payings AS p ON pc.paying_id=p.id
		WHERE p.Occ = @occ1
			AND (p.id = @p2)
		UNION ALL
		SELECT NULL
			 , 'Итого:'
			 , CONVERT(MONEY, SUM(pc.value_cash))
		FROM dbo.Paying_cash AS pc
		JOIN dbo.Payings AS p ON pc.paying_id=p.id
		WHERE p.Occ = @occ1
			AND (p.id = @p2)
		ORDER BY 1 DESC
	END
	--endregion

	--region 22 Раскидка платежа по услугам (в Картотеке)
	IF (@p1 = 22)
		AND (@p2 <> 0)
	BEGIN
		SELECT CONVERT(VARCHAR(12), pd.day, 106) AS 'Дата платежа'
			 , s.name AS 'Услуга'
			 , CAST(ps.Value AS DECIMAL(10, 4)) AS 'Сумма'
			 , NULLIF(ps.PaymAccount_peny, 0) AS 'из них пени'
			 , CAST((ps.Value - COALESCE(ps.PaymAccount_peny, 0)) AS DECIMAL(10, 4)) AS 'Оплата без пени'
			 , NULLIF(ps.commission, 0) AS 'Комиссия'
			 , vp.PaymAccount AS 'Оплата в квит'
		FROM dbo.Paying_serv AS ps 
			JOIN dbo.View_services_access AS s ON 
				ps.service_id = s.id
			JOIN dbo.Payings AS p ON 
				p.id = ps.paying_id
			JOIN dbo.Paydoc_packs AS pd ON 
				p.pack_id = pd.id
			LEFT JOIN dbo.View_paym vp ON 
				p.fin_id=vp.fin_id 
				AND p.occ=vp.Occ 
				AND p.sup_id=vp.sup_id 
				AND ps.service_id=vp.service_id
		WHERE p.id = @p2
			AND p.Occ = @occ1
		ORDER BY s.short_name
	END
	--endregion

	--region 23 - Комментарии по дому и л/счёту  (в Картотеке)
	IF (@p1 = 23)
	--AND (@p2 = 0)
	BEGIN
		SELECT dbo.Fun_NameFinPeriodDate(o.start_date) AS 'Фин.период'
			 , o.comments AS 'по лиц/сч Договор (комментарий)'
			 , o.comments2 AS 'по лиц/сч в шапке'
			 , o.comments_print AS 'по лиц/сч в квитанции'
			 , b.comments AS 'в доме'
			 , bc.comments AS 'по дому в квитанции'
		FROM dbo.View_occ_all AS o 
			JOIN dbo.Buildings b ON o.build_id = b.id
			LEFT JOIN dbo.Buildings_comments bc ON o.fin_id = bc.fin_id
				AND o.build_id = bc.build_id
		WHERE o.Occ = @occ1
			AND (o.comments IS NOT NULL OR o.comments2 IS NOT NULL OR o.comments_print IS NOT NULL OR b.comments IS NOT NULL OR bc.comments IS NOT NULL)
		ORDER BY o.fin_id DESC
	END
	--endregion

	--region 24 - Водоотведение по ХВС/ГВС по л/счёту  (в Картотеке)
	IF (@p1 = 24)
	--AND (@p2 = 0)
	BEGIN
		SELECT dbo.Fun_NameFinPeriodDate(vv.start_date) AS 'Фин.период'
			 , vv.service_name AS 'Услуга'
			 , vv.tarif AS 'Тариф'
			 , vv.kol AS 'Объём'
			 , vv.Value AS 'Сумма'
			 , vv.service_id AS 'код основной услуги'
			 , CASE
                   WHEN vv.is_counter > 0 THEN 'Есть'
                   ELSE ''
            END AS 'ИПУ'
			 , vv.metod_name AS 'Метод'
			 , vv.unit_id AS 'Ед.изм.'
			 , vv.kol_norma AS 'Норматив'
			 , vv.kol_norma_single AS 'Норма на 1'
			 , vv.occ_sup_paym AS 'Л/сч'
			 , NULLIF(vv.sup_id, 0) AS 'Поставщик'
			 , vv.date_start
			 , vv.date_end
			 , vv.kol_added
			 , vv.koef_day
		     , vv.fin_id
		FROM dbo.View_votv vv 
		WHERE vv.Occ = @occ1
		ORDER BY vv.fin_id DESC
	END

	--region 25 - Нормативы и объёмы по л/счёту  (в Картотеке)
	IF (@p1 = 25)
	--AND (@p2 = 0)
	BEGIN
		SELECT s.name AS 'Услуга'
			 , bon.kol_norma AS 'Норматив'
			 , bon.kol AS 'Кол-во'
			 , bon.tarif AS 'Тариф'
		FROM dbo.Build_occ_norma bon 
		JOIN dbo.Services s ON bon.service_id = s.id
		WHERE bon.Occ = @occ1
		
	END
go

