-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE           FUNCTION [dbo].[Fun_padeg_fio]
(
@Last_name NVARCHAR(50)=''
,@First_name NVARCHAR(30)=''
,@Second_name NVARCHAR(30)=''
,@padeg NVARCHAR(1) = 'Д'  -- код падежа на выходе
,@sex NVARCHAR(3) = 'МУЖ' -- пол 'МУЖ','ЖЕН'
)
RETURNS VARCHAR(120)
AS
/*
SELECT TOP 1000 [dbo].[Fun_padeg_fio](Last_name,First_name,Second_name,'Д',
	CASE WHEN(sex = 1) THEN 'МУЖ' ELSE CASE WHEN (sex = 0) THEN 'ЖЕН' ELSE NULL END END) FROM dbo.People
*/
BEGIN

	DECLARE @fio_in NVARCHAR(120) = CONCAT(@Last_name, ' ', @First_name, ' ', @Second_name)
		,@fio_out NVARCHAR(120)
		,@question NVARCHAR(30)

	SELECT @Last_name = LOWER(LTRIM(RTRIM(@Last_name)))
		, @First_name = LOWER(LTRIM(RTRIM(@First_name)))
		, @Second_name = LOWER(LTRIM(RTRIM(@Second_name)))
	SELECT @Last_name = UPPER(LEFT(@Last_name, 1))+SUBSTRING(@Last_name,2,50)
		,@First_name = UPPER(LEFT(@First_name, 1))+SUBSTRING(@First_name,2,30)
		,@Second_name = UPPER(LEFT(@Second_name, 1))+SUBSTRING(@Second_name,2,30)
	
	SELECT @padeg=COALESCE(@padeg,'Д'), @sex = COALESCE(UPPER(@sex),'МУЖ')
	SELECT @question = CASE @padeg
		WHEN 'Д' THEN 'справка выдана кому?'
		WHEN 'Р' THEN 'заявление от кого?'
		WHEN 'Т' THEN 'проживает совместно с кем?'
		ELSE '?'
	END
    
	-- таблицы исключений
	DECLARE @except TABLE (
		part NVARCHAR(1),  -- часть ФИО, возможные значения: F,I,O
		val NVARCHAR(120),  -- в именительном пдеже
		val_dat NVARCHAR(120), -- в дательном
		val_rod NVARCHAR(120), -- в родительном
		val_tvor NVARCHAR(120), -- в творительном
		PRIMARY KEY (part, val))

	INSERT INTO @except VALUES 
	('F','Цой','Цою','Цоя','Цоем')
	INSERT INTO @except VALUES 
	('I','Игорь','Игорю','Игоря','Игорем'),
	('I','Илья','Илье','Ильи','Ильёй'),
	('I','Павел','Павлу','Павла','Павлом'),
	('I','Пётр','Петру','Петра','Петром'),
	('I','Лев','Льву','Льва','Львом'),
	('I','Ян','Яну','Яна','Яном'),
	('I','Алия','Алие','Алии','Алиёй'),
	('I','Лия','Лие','Лии','Лией'),
	('I','Айгуль','Айгуль','Айгуль','Айгуль')
	INSERT INTO @except VALUES 
	('O','Ильич','Ильичу','Ильича','Ильичом'), 
	('O','Кузьмич','Кузьмичу','Кузьмича','Кузьмичом')

	IF @padeg='Д'
	BEGIN
		--IF @debug=1 PRINT 'Дательный'
		-- Фамилия ==============================================
			IF @sex='ЖЕН' AND RIGHT(@Last_name, 1) IN ('к','ч','б','в','н','р','й','г','ц')
				GOTO First_name_DAT

			IF EXISTS(SELECT 1 From @except WHERE part='F' AND val=@Last_name)
			BEGIN -- ищем исключения
				SELECT @Last_name=val_dat FROM @except WHERE part='F' AND val=@Last_name
				GOTO First_name_DAT
			END
			IF dbo.strpos(' ', @Last_name) > 0
				GOTO First_name_DAT

			IF RIGHT(@Last_name, 2) = 'ок'
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ку')

			IF @sex='МУЖ' AND RIGHT(@Last_name, 1) IN  ('к', 'ч', 'в', 'н', 'б', 'р','л')
				SET @Last_name = CONCAT(@Last_name, 'у')
					  
			IF RIGHT(@Last_name, 1) IN ('а')
			BEGIN
				IF RIGHT(@Last_name, 2) IN ('ча','ра','ка')
					SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'е')
				ELSE
					SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'ой')
				
				GOTO First_name_DAT
			END

			IF RIGHT(@Last_name, 1) = 'й'
				IF RIGHT(@Last_name, 2) = 'ей'
					SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ею')
				ELSE
					SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ому')
			
			IF RIGHT(@Last_name, 1) = 'я'
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ой')

			IF RIGHT(@Last_name, 2) = 'ец' AND LEN(@Last_name)>3
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'цу')
		-- Имя ==============================================
		First_name_DAT:
			IF EXISTS(SELECT 1 From @except WHERE part='I' AND val=@First_name)
			BEGIN -- ищем исключения
				SELECT @First_name=val_dat FROM @except WHERE part='I' AND val=@First_name
				GOTO Second_name_DAT
			END
			IF LEN(@First_name)<=1
				GOTO Second_name_DAT
			IF dbo.strpos(' ', @First_name) > 0
				GOTO Second_name_DAT

			IF RIGHT(@First_name, 2)='ия'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'и')
			IF RIGHT(@First_name, 2)='ьи'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'ье')

			IF RIGHT(@First_name, 1)='й'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'ю')

			-- Женские имена, оканчивающиеся на твердую согласную, как правило, не склоняются: Катрин, Марьям, Элизабет, Ирен.
			IF @sex='ЖЕН' AND RIGHT(@First_name, 1) in ('н','м','т', 'б', 'в', 'г', 'д', 'ж', 'з', 'й', 'к', 'л', 'п', 'р', 'с', 'ф', 'х', 'ц', 'ч', 'ш')
				GOTO Second_name_DAT

			IF RIGHT(@First_name, 1) in ('л', 'р', 'м', 'н', 'в', 'г', 'д', 'с', 'т', 'б', 'к', 'п')
				SET @First_name = CONCAT(@First_name, 'у')

			IF RIGHT(@First_name, 1) in ('а', 'я')
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'е')	  

			IF RIGHT(@First_name, 1) in ('ь')
				IF @sex='ЖЕН'
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'и')
				ELSE
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'ю')

		-- Отчество ==============================================
		Second_name_DAT:
			IF EXISTS(SELECT 1 From @except WHERE part='O' AND val=@Second_name)
			BEGIN -- ищем исключения
				SELECT @Second_name=val_dat FROM @except WHERE part='O' AND val=@Second_name
				GOTO LABEL_OUT
			END
			IF LEN(@Second_name)<=2
				GOTO LABEL_OUT
			IF dbo.strpos(' ', @Second_name) > 0
				GOTO LABEL_OUT

			IF RIGHT(@Second_name, 1) = 'а'
				IF RIGHT(@Second_name, 2) = 'ва'
					SET @Second_name = CONCAT(SUBSTRING(@Second_name, 1, LEN(@Second_name)-1), 'ой')
				ELSE
					SET @Second_name = CONCAT(SUBSTRING(@Second_name, 1, LEN(@Second_name)-1),  'е')

			IF RIGHT(@Second_name, 1) IN ('ч', 'т')
				SET @Second_name = CONCAT(@Second_name, 'у')

	END
	IF @padeg='Р'
	BEGIN
		--if @debug=1 PRINT 'Родительный'
		-- Фамилия ==============================================
		IF @sex='ЖЕН' AND RIGHT(@Last_name, 1) IN ('к','ч','б','в','н','р','й','ь','г','ц')
			GOTO First_name_ROD

		IF EXISTS(SELECT 1 From @except WHERE part='F' AND val=@Last_name)
		BEGIN -- ищем исключения
			SELECT @Last_name=val_rod FROM @except WHERE part='F' AND val=@Last_name
			GOTO First_name_ROD
		END
		IF dbo.strpos(' ', @Last_name) > 0
			GOTO First_name_ROD
		
		IF RIGHT(@Last_name, 2) = ('ок')
		BEGIN
			SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ка')
			GOTO First_name_ROD
		END

		IF RIGHT(@Last_name, 1) IN ('к','ч','б','л','г')
		BEGIN
			SET @Last_name = CONCAT(@Last_name, 'а')
			GOTO First_name_ROD
		END

		IF RIGHT(@Last_name, 1) IN ('а')
		BEGIN
			IF @sex='ЖЕН'
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'ой')
			ELSE
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'и')
			GOTO First_name_ROD
		END

		IF RIGHT(@Last_name, 1) IN ('в','н','р')
			SET @Last_name = CONCAT(@Last_name, 'а')

		IF RIGHT(@Last_name, 1) = 'й'
			IF @sex='МУЖ'
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2), 'ого')
			ELSE
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2), 'ова')

		IF RIGHT(@Last_name, 1) ='я'
		BEGIN
			SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ой')
			GOTO First_name_ROD
		END
		IF RIGHT(@Last_name, 2) = 'ец' AND LEN(@Last_name)>3
			SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ца')

		-- Имя ==============================================
		First_name_ROD:
			IF EXISTS(SELECT 1 From @except WHERE part='I' AND val=@First_name)
			BEGIN -- ищем исключения
				SELECT @First_name=val_rod FROM @except WHERE part='I' AND val=@First_name
				GOTO Second_name_ROD
			END
			IF LEN(@First_name)<=2
				GOTO Second_name_ROD
			IF dbo.strpos(' ', @First_name) > 0
				GOTO Second_name_ROD

			IF RIGHT(@First_name, 1) = 'а' 
				IF RIGHT(@First_name, 2) = 'ка'
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'и')
				ELSE
				IF RIGHT(@First_name, 2) = 'га'
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'и')
				ELSE
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'ы')

			IF RIGHT(@First_name, 1) IN ('л','р','м','н','с','в','д','г','к','б','т','ф','х','з','п')
				IF @sex='МУЖ'
					SET @First_name = CONCAT(@First_name, 'а')

			IF RIGHT(@First_name, 1) = 'я'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'и')

			IF RIGHT(@First_name, 1) = 'й'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1),  'я')

			IF RIGHT(@First_name, 1) in ('ь')
				IF @sex='ЖЕН'
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'и')
				ELSE
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'я')

		-- Отчество ==============================================
		Second_name_ROD:
			IF EXISTS(SELECT 1 From @except WHERE part='O' AND val=@Second_name)
			BEGIN -- ищем исключения
				SELECT @Second_name=val_rod FROM @except WHERE part='O' AND val=@Second_name
				GOTO LABEL_OUT
			END
			IF LEN(@Second_name)<=2
				GOTO LABEL_OUT
			IF dbo.strpos(' ', @Second_name) > 0
				GOTO LABEL_OUT

			IF RIGHT(@Second_name, 1) = 'а'
				IF RIGHT(@Second_name, 2) = 'ва'
					SET @Second_name = CONCAT(SUBSTRING(@Second_name, 1, LEN(@Second_name)-1), 'ой')
				ELSE
					SET @Second_name = CONCAT(SUBSTRING(@Second_name, 1, LEN(@Second_name)-1), 'ы')

			IF RIGHT(@Second_name, 1) = 'ч'
				SET @Second_name = CONCAT(@Second_name, 'а')

	END
	IF @padeg='Т'
	BEGIN
		--if @debug=1 PRINT 'Творительный'
		-- Фамилия ==============================================
			IF @sex='ЖЕН' AND RIGHT(@Last_name, 1) IN ('к','ч','б','в','н','р','й','х','ш','т','д','г','ц')
				GOTO First_name_TVOR

			IF EXISTS(SELECT 1 From @except WHERE part='F' AND val=@Last_name)
			BEGIN -- ищем исключения
				SELECT @Last_name=val_tvor FROM @except WHERE part='F' AND val=@Last_name
				GOTO First_name_TVOR
			END
			IF dbo.strpos(' ', @Last_name) > 0
				GOTO First_name_TVOR
		
			IF RIGHT(@Last_name, 1) IN ('а')
			BEGIN
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'ой')
				GOTO First_name_TVOR
			END
			IF RIGHT(@Last_name, 2) = ('ок')
			BEGIN
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ком')
				GOTO First_name_TVOR
			END
			IF RIGHT(@Last_name, 1) IN ('й')
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-1),  'м')

			IF RIGHT(@Last_name, 2) IN ('он', 'ал', 'ах', 'ях', 'ан', 'ян', 'рг') 
			BEGIN
				SET @Last_name = CONCAT(@Last_name, 'ом')
				GOTO First_name_TVOR
			END

			IF RIGHT(@Last_name, 1) IN ('в','н') --
				SET @Last_name = CONCAT(@Last_name, 'ым')
			IF RIGHT(@Last_name, 1) IN ('ч','ш')
				SET @Last_name = CONCAT(@Last_name, 'ем')
			IF RIGHT(@Last_name, 1) IN ('к','р','б','д','т') 
				SET @Last_name = CONCAT(@Last_name, 'ом')

			IF RIGHT(@Last_name, 2) IN ('ая')
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'ой')
			IF RIGHT(@Last_name, 2) = 'ец' AND LEN(@Last_name)>3
				SET @Last_name = CONCAT(SUBSTRING(@Last_name, 1, LEN(@Last_name)-2),  'цем')
		-- Имя ==============================================
		First_name_TVOR:
			IF EXISTS(SELECT 1 From @except WHERE part='I' AND val=@First_name)
			BEGIN -- ищем исключения
				SELECT @First_name=val_tvor FROM @except WHERE part='I' AND val=@First_name
				GOTO Second_name_TVOR
			END
			IF LEN(@First_name)<=2
				GOTO Second_name_TVOR
			IF dbo.strpos(' ', @First_name) > 0
				GOTO Second_name_TVOR

			IF RIGHT(@First_name, 2) in ('ей', 'ий', 'ай')
			BEGIN
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'ем')
				GOTO Second_name_TVOR
			END
		
			IF @sex='МУЖ' AND RIGHT(@First_name, 1) IN ('р','с','в','н','л','г','д','т','к','м','б','п','ф','з')			
				SET @First_name = CONCAT(@First_name, 'ом')

			IF RIGHT(@First_name, 1) = 'а'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'ой')
			IF RIGHT(@First_name, 1) = 'я'
				SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'ей')

			IF RIGHT(@First_name, 1) IN ('ь')
				IF @sex='ЖЕН'
					SET @First_name = CONCAT(@First_name, 'ю')
				ELSE
					SET @First_name = CONCAT(SUBSTRING(@First_name, 1, LEN(@First_name)-1), 'ем')

		-- Отчество ==============================================
		Second_name_TVOR:
			IF EXISTS(SELECT 1 From @except WHERE part='O' AND val=@Second_name)
			BEGIN -- ищем исключения
				SELECT @Second_name=val_tvor FROM @except WHERE part='O' AND val=@Second_name
				GOTO LABEL_OUT
			END
			IF LEN(@Second_name)<=2
				GOTO LABEL_OUT
			IF dbo.strpos(' ', @Second_name) > 0
				GOTO LABEL_OUT

			IF RIGHT(@Second_name, 1) = 'ч'
				IF @sex='МУЖ'
					SET @Second_name = CONCAT(@Second_name, 'ем')

			IF RIGHT(@Second_name, 1) = 'а'
				SET @Second_name = CONCAT(SUBSTRING(@Second_name, 1, LEN(@Second_name)-1), 'ой')
	END

	LABEL_OUT:

	SELECT @fio_out=CONCAT(@Last_name, ' ', @First_name, ' ', @Second_name)

	--IF @debug=1
	--	PRINT CONCAT('fio_in=',@fio_in,', padeg=',@padeg,', sex=',@sex,', @question=',@question,', fio_out=', @fio_out)
	
	RETURN @fio_out

END
go

