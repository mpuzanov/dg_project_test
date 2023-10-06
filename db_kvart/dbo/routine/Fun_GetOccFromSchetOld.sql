CREATE   FUNCTION [dbo].[Fun_GetOccFromSchetOld]
(
	  @Schetl VARCHAR(10)
)
RETURNS INT
AS
BEGIN
	/*
		Возвращаем единый лицевой счет по заданному числу 
		если по этой услуге разрешено отдельно платить

	select [dbo].[Fun_GetOccFromSchetOld](560291266)

	*/
	DECLARE @res INT = NULL
	,@schtl_int INT = CAST(@Schetl AS INT)

	SELECT @res = occ
	FROM dbo.Occupations
	WHERE (occ = @schtl_int)
	OR (schtl = @schtl_int)
	OR (schtl_old = @Schetl)

	IF @res>0
		RETURN @res
	--================================================

	DECLARE @service_kod1 TINYINT
		  , @occ2 INT = NULL
		  , @service_id1 VARCHAR(10)

	--IF @schet1 <= 9999999
	--	GOTO LABEL_END -- 6,7 значный код не обрабатываем

	SELECT TOP 1 @occ2 = occ
	FROM dbo.Occ_Suppliers OS
	WHERE occ_sup = @schtl_int

	IF @occ2 IS NOT NULL
	BEGIN
		SET @res = @occ2
		GOTO LABEL_END
	END

	IF (@schtl_int > 9999999) -- 8 значный код
	BEGIN
		SELECT @service_kod1 = @schtl_int / 10000000
		SELECT @occ2 = (@schtl_int % 10000000) / 10
	END

	IF (@schtl_int > 99999999) -- 9 значный код с поставщиком
	BEGIN
		DECLARE @sup_id INT = 0
		SELECT @sup_id = dbo.Fun_GetSUPFromSchetl(@schtl_int)
		IF COALESCE(@sup_id, 0) > 0
			SELECT @res = (@schtl_int % 1000000)
		GOTO LABEL_END
	END

	SELECT @service_id1 = id
	FROM dbo.Services 
	WHERE service_kod = @service_kod1

	IF EXISTS (
			SELECT 1
			FROM dbo.Consmodes_list
			WHERE occ = @occ2
				AND service_id = @service_id1
				AND (is_counter > 0 OR account_one = 1)
		)
	BEGIN
		SET @res = @occ2
	END


LABEL_END:
	RETURN @res
END
go

