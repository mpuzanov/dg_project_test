CREATE   PROCEDURE [dbo].[k_meas_units]
(
	@serv1			VARCHAR(10) = NULL
	,@is_counter1	BIT			= 0 -- по счетчикам
	,@tip_id1		SMALLINT	= NULL
	,@fin_id1		SMALLINT	= NULL
)
AS
	/*
	
	Выдаем нормы по режимам потребления
	
	дата создания: 
	автор: Пузанов М.А.
	
	дата последней модификации:  
	автор изменений: Пузанов М.А.
	
	изменения:
	работу со счетчиками
	
	*/
	SET NOCOUNT ON


	DECLARE	@is_counter2	SMALLINT
			,@fin_current	SMALLINT

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0
	IF @serv1 IS NULL
		SET @serv1 = '????'
	IF @is_counter1 IS NULL
		SET @is_counter1 = 0

	SET @is_counter2 = CASE
                           WHEN @is_counter1 = 1 THEN 1
                           ELSE 0
        END

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)

	IF @serv1 = '????'
	BEGIN
		SELECT
			mu.id
			,OT.name as 'Тип фонда'
			,u.name as 'Ед.измерения'
			,CAST('Все' AS VARCHAR(30)) as 'Режим потребления'
			,dbo.Fun_NameFinPeriod(mu.fin_id) as 'Фин.период'
			,u1.Initials as 'Пользователь'
			,mu.mode_id
			,mu.fin_id			
			,mu.unit_id
			,mu.is_counter
			,mu.tip_id
			,mu.q_single
			,mu.two_single
			,mu.three_single
			,mu.four_single
			,mu.q_member
			,mu.norma_extr_tarif
			,mu.norma_full_tarif
		FROM dbo.MEASUREMENT_UNITS AS mu
		JOIN dbo.UNITS AS u 
			ON mu.unit_id = u.id
		JOIN dbo.OCCUPATION_TYPES AS OT
			ON mu.tip_id = OT.id
		LEFT JOIN dbo.USERS AS u1
			ON mu.user_edit = u1.id
		WHERE mu.mode_id = 0
			AND mu.fin_id = @fin_id1
			AND is_counter = @is_counter2
			AND mu.tip_id = COALESCE(@tip_id1, 0)
	END
	ELSE
	BEGIN
		SELECT
			mu.id
			,OT.name as 'Тип фонда'
			,s.name as 'Услуга'
			,u.name as 'Ед.измерения'
			,cm.name as 'Режим потребления'
			,dbo.Fun_NameFinPeriod(mu.fin_id) as 'Фин.период'
			,u1.Initials as 'Пользователь'
			,mu.mode_id
			,mu.fin_id		
			,mu.unit_id
			,mu.is_counter
			,mu.tip_id
			,mu.q_single
			,mu.two_single
			,mu.three_single
			,mu.four_single
			,mu.q_member
			,mu.norma_extr_tarif
			,mu.norma_full_tarif
		FROM dbo.MEASUREMENT_UNITS AS mu
		JOIN dbo.UNITS AS u 
			ON mu.unit_id = u.id
		JOIN dbo.CONS_MODES AS cm 
			ON mu.mode_id = cm.id
		JOIN dbo.SERVICES AS s
			ON cm.service_id = s.id
		JOIN dbo.OCCUPATION_TYPES AS OT
			ON mu.tip_id = OT.id
		LEFT JOIN dbo.USERS AS u1 
			ON mu.user_edit = u1.id
		WHERE cm.service_id = COALESCE(@serv1, cm.service_id)
			AND mu.is_counter = @is_counter2 --CASE WHEN @is_counter1=0 THEN 0 ELSE 1 END			
			AND mu.tip_id = COALESCE(@tip_id1, 0)
			AND mu.fin_id = @fin_id1
		ORDER BY mu.mode_id
	END
go

