-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	набор расчетов по лицевому счёту (пени + квартплата)
-- =============================================
CREATE         PROCEDURE [dbo].[k_raschet_all](
  @occ1 INT
, @fin_id1 SMALLINT = NULL
, @sup_id1 INT = NULL
, @debug BIT = 0
, @flat_id1 INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @er INT
        , @occ_sup INT

	IF @fin_id1 IS NULL
		SET @fin_id1=dbo.Fun_GetFinCurrent(NULL,NULL,@flat_id1,@occ1)

	-- расчет пени по поставщикам
	DECLARE curs CURSOR LOCAL FOR
		SELECT os.occ_sup
        FROM Occ_Suppliers os 
        WHERE occ = @occ1
            AND os.fin_id = @fin_id1
            AND (os.sup_id = @sup_id1 or @sup_id1 is NULL)
	OPEN curs
	FETCH NEXT FROM curs INTO @occ_sup
	WHILE (@@fetch_status = 0)
	BEGIN
          
        -- Расчет пени по поставщику
        EXEC @er = dbo.k_raschet_peny_sup_new @occ_sup = @occ_sup
            , @fin_id1 = @fin_id1
            , @debug = @debug

		FETCH NEXT FROM curs INTO @occ_sup
	END
	CLOSE curs
	DEALLOCATE curs
    
    -- Расчет по ИПУ
    if @flat_id1 is not null
        EXEC @er = dbo.k_counter_raschet_flats2 @flat_id1
            , 1
            , 0

    -- Расчет пени по ед.лицевому
    EXEC @er = dbo.k_raschet_peny @occ1 = @occ1
		, @fin_id1 = @fin_id1
        , @debug = @debug

    -- Расчитываем квартплату
    EXEC @er = dbo.k_raschet_2 @occ1 = @occ1
        , @fin_id1 = @fin_id1
        , @debug= @debug

END
go

