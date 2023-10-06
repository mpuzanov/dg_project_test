-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE               PROCEDURE [dbo].[k_counter_find_adres](
    @street_name VARCHAR(50) = NULL
, @nom_dom VARCHAR(12) = NULL
, @nom_kvr VARCHAR(20) = NULL
, @serial_number VARCHAR(20) = NULL
, @occ INT = NULL
, @counter_uid VARCHAR(36) = NULL -- убрать 
)
AS
/*
exec k_counter_find_adres @street_name='К.Маркса',@nom_dom='177',@nom_kvr='11',@serial_number='1310782  к 19',@occ=177013
exec k_counter_find_adres @street_name='30 лет Победы',@nom_dom='33',@nom_kvr='3',@serial_number='27307936',@occ=33003
exec k_counter_find_adres @street_name='30 лет Победы',@nom_dom='33',@nom_kvr='3',@serial_number='27307936',@occ=1033003
exec k_counter_find_adres @counter_uid='85F49D11-9D00-43BD-9141-F81F93A89E7D'
*/
BEGIN
    SET NOCOUNT ON;

    IF @counter_uid=''
        set @counter_uid=NULL
    
    IF ((@street_name IS NULL)
        AND (@nom_dom IS NULL)
        AND (@nom_kvr IS NULL)
        AND (@occ IS NULL)) AND @counter_uid is null
        BEGIN
            RAISERROR (N'Входные параметры не заполнены!', 16, 1)
        END

    IF (@street_name = '')
        OR (@nom_dom = '')
        OR (@nom_kvr = '')
        BEGIN
            SELECT @street_name = NULL
                 , @nom_dom = NULL
                 , @nom_kvr = NULL
        END

    IF @occ > 0
        SET @occ = dbo.Fun_GetFalseOccIn(@occ)

    DECLARE @t TABLE
               (
                   id       INT,
                   tip_name VARCHAR(50),
                   occ      INT,
				   service_id VARCHAR(10),
				   flat_id  INT
               )
        
    INSERT INTO @t ( id
                   , tip_name
                   , occ
				   , service_id
				   , flat_id)
    SELECT DISTINCT c.id
         , ot.name AS tip_name
         , cl.occ
		 , c.service_id
		 , c.flat_id
    FROM dbo.Counters AS c             
             JOIN dbo.Flats AS f 
				ON f.id = c.flat_id
             JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
             JOIN dbo.VStreets AS s
				ON b.street_id = s.id
             JOIN dbo.Occupation_Types AS ot 
				ON b.tip_id = ot.id
             JOIN dbo.Counter_list_all AS cl 
				ON c.id = cl.counter_id
			 JOIN dbo.Occupations AS o 
				ON o.flat_id = f.id			 
				AND o.occ = cl.occ 
				AND cl.fin_id = b.fin_current
			 LEFT JOIN dbo.Occ_Suppliers AS os 
				ON os.occ = o.occ
    WHERE b.is_paym_build = cast(1 as bit)
      AND ot.payms_value = cast(1 as bit)
      AND ot.raschet_no = cast(0 as bit)
      AND (
			--(c.counter_uid=@counter_uid)
   --         OR
            (o.occ = @occ AND c.serial_number = @serial_number) 
            OR
            ((s.name = @street_name OR s.short_name = @street_name OR @street_name IS NULL) AND
             (b.nom_dom = @nom_dom OR @nom_dom IS NULL) AND (f.nom_kvr = @nom_kvr OR @nom_kvr IS NULL) AND
             c.serial_number = @serial_number AND o.occ = @occ) 
            OR            
            ((s.name = @street_name OR s.short_name = @street_name OR @street_name IS NULL) AND
             (b.nom_dom = @nom_dom OR @nom_dom IS NULL) AND (f.nom_kvr = @nom_kvr OR @nom_kvr IS NULL) AND
             c.serial_number = @serial_number AND @occ IS NULL)
			 OR
			 ((os.occ_sup = @occ) AND c.serial_number = @serial_number) 
        )

    --IF NOT EXISTS(SELECT * FROM @t)
    --    BEGIN
    --        -- ищем по поставщику
    --        INSERT INTO @t ( id
    --                       , tip_name
    --                       , occ
				--		   , service_id)
    --        SELECT c.id
    --             , ot.name AS tip_name
    --             , cl.occ
				-- , c.service_id
    --        FROM dbo.Counters AS c 
    --                 JOIN dbo.Occupations AS o  ON c.flat_id = o.flat_id
    --                 JOIN dbo.Occ_Suppliers AS os ON os.occ = o.occ
    --                 JOIN dbo.Flats AS f ON o.flat_id = f.id
    --                 JOIN dbo.Buildings AS b ON f.bldn_id = b.id
    --                 JOIN dbo.VStreets AS s ON b.street_id = s.id
    --                 JOIN dbo.Occupation_Types AS ot ON b.tip_id = ot.id
    --                 JOIN dbo.Counter_list_all AS cl ON c.id = cl.counter_id
    --            AND o.occ = cl.occ
    --            AND cl.fin_id = b.fin_current
    --        WHERE b.is_paym_build = 1
    --          AND ot.payms_value = 1
    --          AND ot.raschet_no = 0
    --          AND (
    --                ((os.occ_sup = @occ OR @occ IS NULL) AND c.serial_number = @serial_number) OR
    --                ((s.name = @street_name OR s.short_name = @street_name OR @street_name IS NULL) AND
    --                 (b.nom_dom = @nom_dom OR @nom_dom IS NULL) AND (f.nom_kvr = @nom_kvr OR @nom_kvr IS NULL) AND
    --                 c.serial_number = @serial_number AND (os.occ_sup = @occ OR @occ IS NULL)) OR
    --                ((s.name = @street_name OR s.short_name = @street_name OR @street_name IS NULL) AND
    --                 (b.nom_dom = @nom_dom OR @nom_dom IS NULL) AND (f.nom_kvr = @nom_kvr OR @nom_kvr IS NULL) AND
    --                 c.serial_number = @serial_number)
    --            )

    --    END

    SELECT *
    FROM @t

END
go

