CREATE   FUNCTION [dbo].[Fun_ChangeCodePageStr](
    @inStr VARCHAR(1000)
, @setCodePage VARCHAR(10) = 'WIN' -- DOS
)
    RETURNS VARCHAR(500)
AS
BEGIN
    /*
    
    Смена кодировки строки
    
    select [dbo].[Fun_ChangeCodePageStr]('Привет','DOS')
    select [dbo].[Fun_ChangeCodePageStr]('ЏаЁўҐв','WIN')
    
    */
    DECLARE @i INT
        ,@inChar INT
        ,@outChar INT
        ,@str VARCHAR(500)

    -- Таблица соответствия кодов символов
    DECLARE @t_CodePage TABLE
                        (
                            dos INT,
                            win INT,
                            UNIQUE (dos, win),
                            UNIQUE (win, dos)
                        )
    --============================================================================
    INSERT INTO @t_CodePage (dos, win)
    SELECT n, 32
    FROM dbo.Fun_GetNums(0, 32)

    INSERT INTO @t_CodePage (dos, win)
    SELECT n, n
    FROM dbo.Fun_GetNums(33, 127) --45-127 -- совпадают

    INSERT INTO @t_CodePage (dos, win)
    VALUES (128, 192),
           (129, 193),
           (130, 194),
           (131, 195),
           (132, 196),
           (133, 197),
           (134, 198),
           (135, 199),
           (136, 200),
           (137, 201),
           (138, 202),
           (139, 203),
           (140, 204),
           (141, 205),
           (142, 206),
           (143, 207),
           (144, 208),
           (145, 209),
           (146, 210),
           (147, 211),
           (148, 212),
           (149, 213),
           (150, 214),
           (151, 215),
           (152, 216),
           (153, 217),
           (154, 218),
           (155, 219),
           (156, 220),
           (157, 221),
           (158, 222),
           (159, 223),
           (160, 224),
           (161, 225),
           (162, 226),
           (163, 227),
           (164, 228),
           (165, 229),
           (166, 230),
           (167, 231),
           (168, 232),
           (169, 233),
           (170, 234),
           (171, 235),
           (172, 236),
           (173, 237),
           (174, 238),
           (175, 239);

    INSERT INTO @t_CodePage (dos, win)
    SELECT n, 32
    FROM dbo.Fun_GetNums(176, 219)

    INSERT INTO @t_CodePage (dos, win)
    VALUES (220, 32),
           (221, 32),
           (222, 32),
           (223, 32),
           (224, 240),
           (225, 241),
           (226, 242),
           (227, 243),
           (228, 244),
           (229, 245),
           (230, 246),
           (231, 247),
           (232, 248),
           (233, 249),
           (234, 250),
           (235, 251),
           (236, 252),
           (237, 253),
           (238, 254),
           (239, 255),
           (240, 168),
           (241, 184),
           (242, 178),
           (243, 179),
           (244, 32),
           (245, 32),
           (246, 175),
           (247, 191),
           (248, 170),
           (249, 186),
           (250, 32),
           (251, 177),
           (252, 185),
           (253, 32),
           (254, 32),
           (255, 32);
    --============================================================================

    SET @i = 1
    SET @str = ''

    WHILE @i <= LEN(@inStr)
        BEGIN
            SET @inChar = ASCII(SUBSTRING(@inStr, @i, 1))

            IF @setCodePage = 'DOS'
                SELECT @outChar = dos FROM @t_CodePage WHERE win = @inChar
            ELSE
                SELECT @outChar = win FROM @t_CodePage WHERE dos = @inChar

            SET @i = @i + 1
            SET @str = @str + CHAR(@outChar)
        END

    RETURN @str

END
go

