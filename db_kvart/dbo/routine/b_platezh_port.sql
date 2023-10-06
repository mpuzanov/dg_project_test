CREATE   PROCEDURE [dbo].[b_platezh_port]
(
	@file	VARCHAR(50)
	,@month	SMALLINT
	,@date	SMALLDATETIME
	,@ext	VARCHAR(10)	= NULL
)
AS
/*
	--  ввод платежа из банков во временную таблицу bank_dbf2_tmp 
*/
	SET NOCOUNT ON;


	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	IF @ext IS NULL
		OR @ext = ''
		SET @ext = SUBSTRING(@file, 1, 3)

	--проверяем не был ли этот файл уже занесен в базу
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_TBL_SPISOK
			WHERE filenamedbf = @file)
	BEGIN
		RAISERROR ('Файл %s уже был загружен ранее!', 16, 10, @file)
		RETURN 1
	END

	-- Проверяем вид платежа
	IF NOT EXISTS (SELECT 1
			FROM dbo.View_PAYCOLL_ORGS
			WHERE ext = @ext)
	BEGIN
		DELETE FROM BANK_DBF2_TMP
		RAISERROR ('Установите вид платежа!', 16, 10)
		RETURN 1;
	END

	-- таблица со списком типов фонда по которым может импортировать платежи пользователь
	DECLARE @t_tipe_user TABLE
		(
			tip_id SMALLINT
		)
	INSERT
	INTO @t_tipe_user
	(tip_id)
		SELECT
			ONLY_TIP_ID
		FROM dbo.USERS_OCC_TYPES
		WHERE SYSUSER = system_user
	IF NOT EXISTS (SELECT
				1
			FROM @t_tipe_user)
	BEGIN -- если нет ограничения то добавляем все типы
		INSERT
		INTO @t_tipe_user
		(tip_id)
			SELECT
				id
			FROM dbo.OCCUPATION_TYPES AS OT
	END
	-- ***********************************************

	--необходимо, т.к. часть данных берется из названия файла по взаимозачетам Excel  
	UPDATE dbo.BANK_DBF2_TMP
	SET	FILENAMEDBF	= @file
		,P_OPL		= @month
		,DATA_PAYM	= dbo.Fun_GetOnlyDate(@date)
		,BANK_ID	= @ext

	--при импорте из файла Excel количество записей больше, чем в самом файле(свойство Map компоненты QImportXLS в Delphi)
	--пустые строки удаляем
	DELETE FROM dbo.BANK_DBF2_TMP
	WHERE occ IS NULL

	--старые лицевые заносятся из поля occ в поле sch_lic
	UPDATE dbo.BANK_DBF2_TMP
	SET SCH_LIC = occ
	WHERE occ IS NOT NULL

	UPDATE b
	SET service_id = dbo.Fun_GetService_idFromSchet(SCH_LIC) -- из лицевого услуги берем код услуги
	FROM dbo.BANK_DBF2_TMP AS b
	WHERE service_id IS NULL

	UPDATE b
	SET	occ			= dbo.Fun_GetOccFromSchet(SCH_LIC) -- из лицевого услуги берем лицевой счет квартиросьемщика
		,sup_id		= dbo.Fun_GetSUPFromSchetl(SCH_LIC)
		,dog_int	= dbo.Fun_GetDOGFromSchetl(SCH_LIC)
	FROM dbo.BANK_DBF2_TMP AS b
	--WHERE sch_lic > 9999999 -- between 9999999 and 99999999

	--проверяем начисляем ли по поставщику по этому лицевому
	UPDATE BANK_DBF2_TMP
	SET occ = NULL
	FROM dbo.BANK_DBF2_TMP AS b
	WHERE COALESCE(b.sup_id,0)>0
	AND NOT EXISTS (SELECT
			1
		FROM dbo.OCC_SUPPLIERS AS os
		WHERE os.occ = b.occ
		AND os.sup_id = b.sup_id)

	
	-- определяем ложные лицевые 06/09/12
	UPDATE b
	SET occ = dbo.Fun_GetFalseOccIn(SCH_LIC)
	FROM dbo.BANK_DBF2_TMP AS b
	WHERE b.occ IS NULL

	-- обнуляем лицевые которых нет в базе
	UPDATE b
	SET occ = NULL
	FROM dbo.BANK_DBF2_TMP AS b
	LEFT JOIN dbo.OCCUPATIONS AS o
		ON b.occ = o.occ
	WHERE o.occ IS NULL
	OR NOT EXISTS (SELECT
			1
		FROM @t_tipe_user t
		WHERE o.tip_id = t.tip_id) -- ограничиваем по типам фонда 12.10.12

	-- очищаем лицевые, по которым блокировка оплаты по типу фонда
	UPDATE b
	SET occ = NULL
	FROM dbo.BANK_DBF2_TMP AS b
	JOIN dbo.OCCUPATIONS AS o
		ON b.occ = o.occ
	JOIN dbo.OCCUPATION_TYPES AS OT
		ON o.tip_id = OT.id
	WHERE OT.tip_paym_blocked = 1
go

