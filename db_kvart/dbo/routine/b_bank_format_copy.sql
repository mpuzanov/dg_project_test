-- =============================================
-- Author:		Name
-- Create date: 
-- Description:	Копируем текущий формат в новую строку
-- =============================================
CREATE PROCEDURE [dbo].[b_bank_format_copy]
(
	@id		INT
   ,@in		SMALLINT = 1 -- 1-BANK_FORMAT, 2-BANK_FORMAT_OUT
   ,@koladd SMALLINT = 0 OUTPUT
)
/*
declare @koladd smallint=0
exec b_bank_format_copy @id='АК БАРС',@in=1,@koladd=@koladd OUTPUT
select @koladd
*/
AS
BEGIN
	SET NOCOUNT ON;
	IF @in IS NULL
		SET @in = 1

	IF @in = 1
	BEGIN
		INSERT INTO [dbo].[BANK_FORMAT]
		([name]
		,[EXT]
		,[code_page]
		,[EXT_BANK]
		,[CHAR_ZAG]
		,[CHAR_RAZD]
		,[LIC_NO]
		,[LIC_SIZE]
		,[DATA_PLAT_NO]
		,[DATA_PLAT_SIZE]
		,[DATESEPARATOR]
		,[DECIMALSEPARATOR]
		,[SUMMA_NO]
		,[SUMMA_SIZE]
		,[ADRES_NO]
		,[ADRES_SIZE]
		,[FILENAME_FILTER]
		,[LIC_NAME]
		,[ADRES_NAME]
		,[COMMIS_NO]
		,[RASCH_NAME]
		,RASCH_NO
		,SERVICE_NO)
			SELECT
				[name] + CAST((SELECT
						COUNT(id) + 1
					FROM [BANK_FORMAT])
				AS VARCHAR(10))
			   ,[EXT]
			   ,[code_page]
			   ,''
			   ,[CHAR_ZAG]
			   ,[CHAR_RAZD]
			   ,[LIC_NO]
			   ,[LIC_SIZE]
			   ,[DATA_PLAT_NO]
			   ,[DATA_PLAT_SIZE]
			   ,[DATESEPARATOR]
			   ,[DECIMALSEPARATOR]
			   ,[SUMMA_NO]
			   ,[SUMMA_SIZE]
			   ,[ADRES_NO]
			   ,[ADRES_SIZE]
			   ,[FILENAME_FILTER]
			   ,[LIC_NAME]
			   ,[ADRES_NAME]
			   ,[COMMIS_NO]
			   ,[RASCH_NAME]
			   ,RASCH_NO
			   ,SERVICE_NO
			FROM [dbo].[BANK_FORMAT]
			WHERE id = @id
		SET @koladd = @@rowcount
	END
	IF @in = 2
	BEGIN
		DECLARE @id_max SMALLINT
		SELECT
			@id_max = MAX(id)
		FROM BANK_FORMAT_OUT bfo
		SET @id_max += 1

		INSERT
		INTO BANK_FORMAT_OUT
		(	id
			,name
			,visible
			,format_tip
			,format_string
			,code_page
			,DECIMALSEPARATOR)
				SELECT
					@id_max
					,([name] + CAST(@id_max AS VARCHAR(10))) AS name
					,visible
					,format_tip
					,format_string
					,code_page
					,DECIMALSEPARATOR
				FROM BANK_FORMAT_OUT
				WHERE id = @id
		SET @koladd = @@rowcount
	END
END
go

