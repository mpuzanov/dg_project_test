-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetDogovorBuild]
(
	@occ INT
)
/*
SELECT dbo.Fun_GetDogovorBuild(680002064)
*/
RETURNS VARCHAR(200)
AS
BEGIN

	DECLARE	@Res				VARCHAR(200)	= ''
			,@dog_num			VARCHAR(20)
			,@dog_date			SMALLDATETIME
			,@dog_date_sobr		SMALLDATETIME
			,@dog_date_protocol	SMALLDATETIME
			,@dog_num_protocol	VARCHAR(20)

	SELECT
		@dog_num = COALESCE(b.dog_num, '')
		,@dog_date = b.dog_date
		,@dog_date_sobr = b.dog_date_sobr
		,@dog_date_protocol = b.dog_date_protocol
		,@dog_num_protocol = COALESCE(b.dog_num_protocol, '')
	FROM dbo.OCCUPATIONS AS o 
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	WHERE o.occ = @occ

	SET @Res = '' --'Договор управления'
	IF @dog_num <> ''
		AND @dog_date IS NOT NULL
		SET @Res = CONCAT('Договор управления №' , @dog_num , ' дата:' , CONVERT(CHAR(12), @dog_date, 104), '.')

	IF @dog_date_sobr IS NOT NULL
		SET @Res = CONCAT(@Res , 'Протокол общего собрания собственников № ' , @dog_num_protocol , ' от ' , CONVERT(CHAR(12), @dog_date_protocol, 104))

	RETURN @Res

END
go

