
-- =============================================
-- Author:		Пузанов
-- Create date: 09.02.2010
-- Description:	Удаляем банковский счет организации
-- =============================================
CREATE PROCEDURE [dbo].[adm_bank_account_del]
(
@id1 INT
)
AS
BEGIN
	SET NOCOUNT ON;

-- Перед удалением проверяем у кого он установлен

	DECLARE @tip1 SMALLINT, @msg VARCHAR(100), @name VARCHAR(100)
	
	SELECT @tip1=tip FROM dbo.ACCOUNT_ORG WHERE id=@id1
	
	IF @tip1=1 --Типы жилого фонда
	BEGIN
	  SELECT @name=name FROM dbo.OCCUPATION_TYPES WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Тип фонда: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END
	
	IF @tip1=2 --Участки
	BEGIN
	  SELECT @name=name FROM dbo.SECTOR WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Участок: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END
	
	IF @tip1=3 --Поставщики
	BEGIN
	  SELECT @name=name FROM dbo.View_SUPPLIERS WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Поставщик: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END
	
	IF @tip1=4 --Район
	BEGIN
	  SELECT @name=name FROM dbo.DIVISIONS WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Район: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END

	IF @tip1=5 --Дом
	BEGIN
	  SELECT @name=adres FROM dbo.View_BUILDINGS WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Дом: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END
	
	IF @tip1=6 --Договор
	BEGIN
	  SELECT @name=dog_name FROM dbo.DOG_SUP WHERE bank_account=@id1
	  IF @name IS NOT NULL
	  BEGIN
	    SET @msg='Банковский счет установлен у '+CHAR(13)+'Договор: '+@name;
	    SET @msg=@msg+CHAR(13)+'Сначала уберите его там (кл.Del)';
		RAISERROR(@msg,16,1);
		RETURN 1
	  END
	END
		
	-- Значит не где не используется - удаляем
	DELETE FROM dbo.ACCOUNT_ORG WHERE id=@id1

END

go

