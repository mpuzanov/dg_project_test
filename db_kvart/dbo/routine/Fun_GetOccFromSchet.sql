CREATE   FUNCTION [dbo].[Fun_GetOccFromSchet]
(
	  @schet1 INT
)
RETURNS INT
AS
BEGIN
	/*
		-- Возвращаем единый лицевой счет по заданному числу 
		-- если по этой услуге разрешено отдельно платить
		select [dbo].[Fun_GetOccFromSchet](560291266)
	*/
	DECLARE @res INT = NULL
		  , @service_kod1 TINYINT
		  , @occ2 INT = NULL
		  , @service_id1 VARCHAR(10)
		  , @schet_str VARCHAR(10) = CAST(@schet1 AS VARCHAR(10))

	SELECT TOP(1) @res = Occ
	FROM dbo.Occupations 
	WHERE Occ = @schet1

	IF @res > 0
		RETURN @res


	SELECT TOP (1) @occ2 = Occ
	FROM dbo.Occ_Suppliers OS
	WHERE occ_sup = @schet1

	IF @occ2 IS NOT NULL
	BEGIN
		SET @res = @occ2
		GOTO LABEL_END
	END

	IF (@schet1 > 9999999) -- 8 значный код
	BEGIN
		SELECT @service_kod1 = @schet1 / 10000000
		SELECT @occ2 = (@schet1 % 10000000) / 10
	END

	IF (@schet1 > 99999999) -- 9 значный код с поставщиком
	BEGIN
		DECLARE @sup_id INT = 0
		SELECT @sup_id = dbo.Fun_GetSUPFromSchetl(@schet1)
		IF COALESCE(@sup_id, 0) > 0
			SELECT @res = (@schet1 % 1000000)
		GOTO LABEL_END
	END

	SELECT @service_id1 = id
	FROM dbo.Services 
	WHERE service_kod = @service_kod1

	IF EXISTS (
			SELECT 1
			FROM dbo.Consmodes_list
			WHERE Occ = @occ2
				AND service_id = @service_id1
				AND (is_counter > 0 OR account_one = 1)
		)
	BEGIN
		SET @res = @occ2
		GOTO LABEL_END
	END

	---- ищем на старых лицевых
	--SELECT @res = Occ
	--FROM dbo.Occupations
	--WHERE schtl = @schet1
	--	OR schtl_old = @schet_str

LABEL_END:
	RETURN @res
END
go

