CREATE   PROCEDURE [dbo].[adm_proverka_modes]
(
	  @send_mail BIT = 1 --  результат выслать по почте
)
AS
	/*
		Поиск не своих режимов
			
		EXEC adm_proverka_modes
	*/
	SET NOCOUNT ON

	EXEC adm_proverka_modes2

	-- таблица с режимами
	DECLARE @t1 TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, id_old INT
		, id_new INT DEFAULT NULL
		, descriptions VARCHAR(30)
	--,PRIMARY KEY (occ,service_id)
	)

	-- таблица с поставщиками
	DECLARE @t2 TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, id_old INT
		, id_new INT DEFAULT NULL
		, descriptions VARCHAR(30)
		, PRIMARY KEY (occ, service_id)
	)

	-- находим не те режимы
	INSERT INTO @t1
	SELECT occ
		 , service_id
		 , mode_id
		 , (mode_id % 1000) + (
			   SELECT id
			   FROM dbo.Cons_modes AS cm 
			   WHERE cm.service_id = cl.service_id
				   AND id % 1000 = 0
		   ) AS id
		 , 'ошибка в режиме потребления'
	FROM dbo.Consmodes_list AS cl
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Cons_modes AS cm 
			WHERE cm.service_id = cl.service_id
				AND id = cl.mode_id
		)
	DELETE cl
	FROM dbo.Consmodes_list AS cl
		JOIN @t1 AS t1 ON cl.occ = t1.occ
			AND cl.service_id = t1.service_id
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Services s 
			WHERE s.id = cl.service_id
		)

	-- изменяем не те режимы
	UPDATE dbo.Consmodes_list
	SET mode_id = id_new
	FROM dbo.Consmodes_list AS cl
		JOIN @t1 AS t1 ON cl.occ = t1.occ
			AND cl.service_id = t1.service_id
	WHERE EXISTS (
			SELECT 1
			FROM dbo.Cons_modes AS cm 
			WHERE cm.service_id = cl.service_id
				AND id = id_new
		)

	-- изменяем режимы на нет
	UPDATE cl
	SET mode_id = t1.id_new
	FROM dbo.Consmodes_list AS cl
		JOIN (
			SELECT occ
				 , service_id
				 , mode_id
				 , (
					   SELECT id
					   FROM dbo.Cons_modes AS cm 
					   WHERE cm.service_id = cl.service_id
						   AND id % 1000 = 0
				   ) AS id_new
				 , 'ошибка в режиме потребления' AS descriptions
			FROM dbo.Consmodes_list AS cl
			WHERE NOT EXISTS (
					SELECT 1
					FROM dbo.Cons_modes AS cm 
					WHERE cm.service_id = cl.service_id
						AND id = cl.mode_id
				)
		) AS t1 ON cl.occ = t1.occ
			AND cl.service_id = t1.service_id

	DELETE FROM @t1
	INSERT INTO @t1
	SELECT occ
		 , service_id
		 , mode_id
		 , (
			   SELECT id
			   FROM dbo.Cons_modes AS cm 
			   WHERE cm.service_id = cl.service_id
				   AND id % 1000 = 0
		   ) AS id
		 , 'ошибка в режиме потребления'
	FROM dbo.Consmodes_list AS cl
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Cons_modes AS cm 
			WHERE cm.service_id = cl.service_id
				AND id = cl.mode_id
		)



	--*****************************************************************
	-- отбираем не тех поставщиков

	-- изменяем неправильных поставщиков
	UPDATE dbo.Consmodes_list
	SET source_id = id_new
	FROM dbo.Consmodes_list AS cl
		JOIN (
			SELECT occ
				 , service_id
				 , source_id
				 , (source_id % 1000) + (
					   SELECT id
					   FROM dbo.Suppliers AS cm 
					   WHERE cm.service_id = cl.service_id
						   AND id % 1000 = 0
				   ) AS id_new
				 , 'ошибка в поставщике' AS descriptions
			FROM dbo.Consmodes_list AS cl
			WHERE NOT EXISTS (
					SELECT 1
					FROM dbo.Suppliers AS cm 
					WHERE cm.service_id = cl.service_id
						AND id = cl.source_id
				)
		) AS t1 ON cl.occ = t1.occ
			AND cl.service_id = t1.service_id
	WHERE EXISTS (
			SELECT 1
			FROM dbo.Suppliers AS cm 
			WHERE cm.service_id = cl.service_id
				AND cm.id = id_new
		)

	-- изменяем поставщиков на нет
	UPDATE cl
	SET source_id = t1.id_new
	FROM dbo.Consmodes_list AS cl
		JOIN (
			SELECT occ
				 , service_id
				 , source_id
				 , (
					   SELECT id
					   FROM dbo.Suppliers AS cm 
					   WHERE cm.service_id = cl.service_id
						   AND id % 1000 = 0
				   ) AS id_new
				 , 'ошибка в поставщике' AS descriptions
			FROM dbo.Consmodes_list AS cl
			WHERE NOT EXISTS (
					SELECT 1
					FROM dbo.Suppliers AS cm 
					WHERE cm.service_id = cl.service_id
						AND id = cl.source_id
				)
		) AS t1 ON cl.occ = t1.occ
			AND cl.service_id = t1.service_id

	DELETE FROM @t2

	INSERT INTO @t2
	SELECT occ
		 , service_id
		 , source_id
		 , (
			   SELECT id
			   FROM dbo.Suppliers AS cm 
			   WHERE cm.service_id = cl.service_id
				   AND id % 1000 = 0
		   ) AS id
		 , 'ошибка в поставщике'
	FROM dbo.Consmodes_list AS cl
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Suppliers AS cm 
			WHERE cm.service_id = cl.service_id
				AND id = cl.source_id
		)

	-- Выдаем список , которые не смог исправить
	INSERT INTO @t1
	SELECT *
	FROM @t2

	IF @send_mail = 0
		SELECT *
		FROM @t1
	ELSE

	IF EXISTS (SELECT 1 FROM @t1)
	BEGIN
		DECLARE @msg VARCHAR(8000)
		SET @msg = 'adm_proverka_modes' + CHAR(13)
		SELECT @msg = @msg + 'Лицевой:' + LTRIM(STR(occ)) + ',Услуга:' + service_id + ',' + descriptions + ',' + LTRIM(STR(id_old)) + '=>' + LTRIM(STR(id_new)) + CHAR(13) + CHAR(10)
		FROM @t1
		--  select @msg
		EXEC dbo.adm_send_mail @msg
	END

	-- Удаляем не нужные нормы(по которым нет режимов потребления)
	DELETE mu
	--OUTPUT DELETED.*,'DELETE From Measurement_units' AS [action]
	FROM dbo.Measurement_units mu
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Cons_modes 
			WHERE id = mu.mode_id
		)
		AND mu.mode_id <> 0

	-- удаление лишних норм (не подходят по еденицам измерения)
	DELETE MU
	--OUTPUT DELETED.*,'DELETE From Measurement_units' AS [action]
	FROM dbo.Measurement_units AS MU
		JOIN dbo.Cons_modes AS cm ON MU.mode_id = cm.id

		LEFT JOIN (
			SELECT DISTINCT su.unit_id
						  , cm2.service_id
						  , cm2.id AS mode_id
			FROM dbo.Service_units AS su 
				JOIN dbo.Cons_modes AS cm2 
					ON su.service_id = cm2.service_id
		) AS t2 ON MU.mode_id = t2.mode_id
			AND cm.service_id = t2.service_id
			AND MU.unit_id = t2.unit_id

		LEFT JOIN (
			SELECT DISTINCT cm2.unit_id
						  , cm2.service_id
						  , cm2.id AS mode_id
			FROM dbo.Service_units AS su 
				JOIN dbo.Cons_modes AS cm2 
					ON su.service_id = cm2.service_id
					AND cm2.unit_id IS NOT NULL
		) AS t3 ON MU.mode_id = t3.mode_id
			AND cm.service_id = t3.service_id
			AND MU.unit_id = t3.unit_id

	WHERE MU.mode_id > 0
		AND (t2.unit_id IS NULL
		AND t3.unit_id IS NULL)


	-- добавляем услуги по которым есть сальдо или оплата
	INSERT INTO dbo.Consmodes_list (occ
								  , service_id
								  , source_id
								  , mode_id
								  , koef
								  , subsid_only
								  , account_one
								  , is_counter
								  , sup_id
								  , fin_id)
	SELECT ph.occ
		 , ph.service_id
		 , (
			   SELECT id
			   FROM dbo.Suppliers AS cm 
			   WHERE cm.service_id = ph.service_id
				   AND id % 1000 = 0
		   ) AS source_id
		 , (
			   SELECT id
			   FROM dbo.Cons_modes AS cm 
			   WHERE cm.service_id = ph.service_id
				   AND id % 1000 = 0
		   ) AS mode_id
		 , 1 AS koef
		 , ph.subsid_only
		 , ph.account_one
		 , COALESCE(ph.is_counter, 0)
		 , ph.sup_id
		 , ph.fin_id
	FROM dbo.Paym_list AS ph 
		JOIN Occupations O 
			ON O.occ = ph.occ
		LEFT JOIN dbo.Consmodes_list CH 
			ON CH.occ = ph.occ
			AND CH.service_id = ph.service_id
	WHERE CH.mode_id IS NULL
		AND (ph.SALDO <> 0 OR ph.PaymAccount <> 0)
go

