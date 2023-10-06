CREATE   FUNCTION [dbo].[sort_string]
(
	  @SortStr VARCHAR(4000)
	, @NumberLength INT
)
RETURNS VARCHAR(4000)
AS
BEGIN
	/*
	https://it-blackcat.blogspot.com/2021/04/sort-by-text-field-with-a-combination-of-letters-and-numbers.html

	SELECT v.nom_kvr, dbo.Fun_SortDom(v.nom_kvr) AS s1, dbo.sort_string(v.nom_kvr,5) AS s2
	FROM Flats v
	WHERE v.bldn_id=6805
	--ORDER BY dbo.Fun_SortDom(v.nom_kvr)
	ORDER BY dbo.sort_string(v.nom_kvr,5)

	SELECT vb.adres, vb.street_name, vb.nom_dom
	FROM View_buildings vb
	WHERE vb.tip_id=1
	--ORDER BY vb.street_name, dbo.Fun_SortDom(vb.nom_dom)
	ORDER BY vb.street_name, dbo.sort_string(vb.nom_dom,5)
	*/
	DECLARE @SortedStr VARCHAR(4000) = @SortStr
		  , @StartIndex INT = PATINDEX('%[0-9]%', @SortStr)
		  , @EndIndex INT = 0
		  , @PadLength INT
		  , @TotalPadLength INT = 0;

	WHILE @StartIndex <> 0
	BEGIN
		SET @StartIndex = @StartIndex + @EndIndex;
		SET @EndIndex = @StartIndex;

		WHILE PATINDEX('[0-9]', SUBSTRING(@SortStr, @EndIndex, 1)) = 1
			SET @EndIndex = @EndIndex + 1;

		SET @PadLength = @NumberLength - (@EndIndex - @StartIndex);

		IF @PadLength > 0
		BEGIN
			SET @SortedStr = STUFF(@SortedStr,
			@TotalPadLength + @StartIndex,
			0,
			REPLICATE('0', @PadLength));
			SET @TotalPadLength = @TotalPadLength + @PadLength;
		END;

		SET @EndIndex = @EndIndex - 1;
		SET @StartIndex = PATINDEX('%[0-9]%',
		RIGHT(@SortStr, LEN(@SortStr) - @EndIndex));
	END;

	RETURN @SortedStr;
END
go

