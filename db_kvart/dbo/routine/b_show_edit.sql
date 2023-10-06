CREATE   PROCEDURE [dbo].[b_show_edit]
(
	@date1	  DATETIME = NULL -- можно выбрать по дате редактирования
   ,@date2	  DATETIME = NULL
   ,@tiporg	  BIT	   = 0 --выбираем просмотр платежей по банкам или организациям
   ,@comments BIT	   = 0 --выбор с опреднленным комментарием
)
AS
	--
	-- Просмотр платежей отредактированных вручную
	--

	/*
	
	дата создания: 26.03.2004
	автор: Пузанов М.А.
	
	дата последней модификации: 30.08.2004
	автор изменений: Кривобоков А.В., добавил  @comments, чтобы в DBank можно было отдельно просматривать удаленные платежи 
	
	*/

	SET NOCOUNT ON


	DECLARE @fin_id1 SMALLINT

	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	IF @tiporg IS NULL
		SET @tiporg = 0

	IF @date2 IS NULL
		AND @date1 IS NULL
	BEGIN
		SET @date2 = current_timestamp
		SET @date1 = DATEADD(MONTH, -3, @date2)
	END

	IF @date2 < @date1
		SET @date2 = @date1


	SELECT
		bl.dateEdit AS 'Дата изменения' 		
	   ,b.sch_lic AS 'Лиц/сч в реестре'
	   ,bl.occ1 AS 'Ст.лицевой'
	   ,bl.occ2 AS 'Нов.лицевой'
	   ,bl.adres1 AS 'Старый адрес'
	   ,bl.adres2 AS 'Новый адрес'
	   ,bl.comments AS 'Комментарий'
	   ,CONVERT(VARCHAR(10), b.sum_opl) AS 'Сумма'
	   ,(SELECT
				SUBSTRING(po.bank_name, 1, 15)
			FROM dbo.View_PAYCOLL_ORGS AS po 
			WHERE b.bank_id = po.ext
			AND po.fin_id = @fin_id1)
		AS 'Банк'
	   ,b.pack_id AS 'Пачка'
	   ,b.pdate AS 'Дата платежа'
	   ,BTS.FILENAMEDBF AS 'Файл'
	   ,u.Initials AS 'Пользователь'
	FROM dbo.BANK_DBF_LOG AS bl 
	JOIN dbo.USERS AS u 
		ON bl.user_id = u.id
	JOIN dbo.BANK_DBF AS b 
		ON b.id = bl.kod_paym
	JOIN dbo.BANK_TBL_SPISOK AS BTS 
		ON b.filedbf_id = BTS.filedbf_id
	WHERE bl.dateEdit BETWEEN COALESCE(@date1, '20020101') AND COALESCE(@date2, '20500101')
	AND bl.comments LIKE CASE
		WHEN @comments = 1 THEN 'платеж удален с суммой%'
		ELSE bl.comments
	END
	ORDER BY bl.id DESC
go

