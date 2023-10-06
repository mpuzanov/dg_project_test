/*************************************************************************/
/*         RubPhrase function for MSSQL2000           */
/*          Gleb Oufimtsev (dnkvpb@nm.ru)            */
/*            http://www.gvu.newmail.ru            */
/*             Moscow Russia 2001             */
/*************************************************************************/
CREATE   FUNCTION [dbo].[Fun_RubPhrase] (@Value MONEY)
RETURNS VARCHAR(255)
AS
/*
select [dbo].[Fun_RubPhrase](1023.99)
select [dbo].[Fun_RubPhrase](1023)
select [dbo].[Fun_RubPhrase](0.31)
*/
BEGIN
	DECLARE @rpart BIGINT, 
			@rattr TINYINT, 
			@cpart TINYINT, 
			@cattr TINYINT

	SET @rpart = FLOOR(@Value)
	SET @rattr = @rpart % 100
	if @rattr>19 
		SET @rattr = @rattr % 10
	SET @cpart = (@Value - @rpart) * 100
	IF @cpart>19 
		SET @cattr = @cpart % 10 ELSE SET @cattr = @cpart
	
	RETURN dbo.Fun_NumPhrase(@rpart,1)+' рубл'+
		CASE 
			WHEN @rattr=1 THEN 'ь' 
			WHEN @rattr in (2,3,4) THEN 'я' 
			ELSE 'ей' 
		END+' '
			+right('0'+CAST(@cpart AS VARCHAR(2)),2)+' копе'
			+CASE 
				WHEN @cattr=1 THEN 'йка' 
				WHEN @cattr in (2,3,4) THEN 'йки' 
				ELSE 'ек' 
			END
END
go

