/*****************************************************/
/*         NumPhrase function for MSSQL2000          */
/*          Gleb Oufimtsev (dnkvpb@nm.ru)			 */
/*            http://www.gvu.newmail.ru				 */
/*             Moscow Russia 2001					 */
/*****************************************************/
CREATE   FUNCTION [dbo].[Fun_NumPhrase](@Num BIGINT, @IsMaleGender bit=1)
    RETURNS VARCHAR(255)
AS
/*
SELECT dbo.Fun_NumPhrase(1450,1)
*/
BEGIN
    DECLARE @nword VARCHAR(255),
        @th TINYINT,
        @gr SMALLINT,
        @d3 TINYINT,
        @d2 TINYINT,
        @d1 TINYINT

    if @Num < 0 RETURN '*** Error: Negative value' ELSE IF @Num = 0 RETURN 'Ноль' /* особый случай */

    WHILE @Num > 0
        BEGIN
            SET @th = COALESCE(@th, 0) + 1
            SET @gr = @Num % 1000
            SET @Num = (@Num - @gr) / 1000
            IF @gr > 0
                BEGIN
                    set @d3 = (@gr - @gr % 100) / 100
                    set @d1 = @gr % 10
                    set @d2 = (@gr - @d3 * 100 - @d1) / 10
                    if @d2 = 1 set @d1 = 10 + @d1
                    set @nword = case @d3
                                     WHEN 1 THEN ' сто'
                                     when 2 then ' двести'
                                     when 3 then ' триста'
                                     WHEN 4 THEN ' четыреста'
                                     when 5 then ' пятьсот'
                                     when 6 then ' шестьсот'
                                     WHEN 7 THEN ' семьсот'
                                     when 8 then ' восемьсот'
                                     when 9 then ' девятьсот'
                                     else '' end
                        + CASE @d2
                              WHEN 2 THEN ' двадцать'
                              when 3 then ' тридцать'
                              when 4 then ' сорок'
                              WHEN 5 THEN ' пятьдесят'
                              when 6 then ' шестьдесят'
                              when 7 then ' семьдесят'
                              WHEN 8 THEN ' восемьдесят'
                              when 9 then ' девяносто'
                              else '' end
                        + CASE @d1
                              WHEN 1 THEN (case
                                               when @th = 2 or (@th = 1 and @IsMaleGender = 0) then ' одна'
                                               else ' один' end)
                              WHEN 2 THEN (case
                                               when @th = 2 or (@th = 1 and @IsMaleGender = 0) then ' две'
                                               else ' два' end)
                              WHEN 3 THEN ' три'
                              when 4 then ' четыре'
                              when 5 then ' пять'
                              WHEN 6 THEN ' шесть'
                              when 7 then ' семь'
                              when 8 then ' восемь'
                              WHEN 9 THEN ' девять'
                              when 10 then ' десять'
                              when 11 then ' одиннадцать'
                              WHEN 12 THEN ' двенадцать'
                              when 13 then ' тринадцать'
                              when 14 then ' четырнадцать'
                              WHEN 15 THEN ' пятнадцать'
                              when 16 then ' шестнадцать'
                              when 17 then ' семнадцать'
                              WHEN 18 THEN ' восемнадцать'
                              when 19 then ' девятнадцать'
                              else '' end
                        + CASE @th
                              WHEN 2 THEN ' тысяч' +
                                          (case when @d1 = 1 then 'а' when @d1 in (2, 3, 4) then 'и' else '' end)
                              WHEN 3 THEN ' миллион'
                              when 4 then ' миллиард'
                              when 5 then ' триллион'
                              when 6 then ' квадрилион'
                              when 7 then ' квинтилион'
                              ELSE '' END
                        + CASE
                              WHEN @th in (3, 4, 5, 6, 7)
                                  then (case when @d1 = 1 then '' when @d1 in (2, 3, 4) then 'а' else 'ов' end)
                              else '' end
                        + COALESCE(@nword, '')
                END
        END
    RETURN UPPER(SUBSTRING(@nword, 2, 1)) + SUBSTRING(@nword, 3, LEN(@nword) - 2)
END
go

