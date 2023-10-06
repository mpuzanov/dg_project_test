-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[adm_pay_cash_create]
(
@tip_id1 SMALLINT
,@fin_id1 SMALLINT = NULL
,@debug BIT = 0
)
AS
/*
adm_pay_cash_create @tip_id1=28,@fin_id1=null,@debug=1
adm_pay_cash_create @tip_id1=28,@fin_id1=203,@debug=1
*/
BEGIN
	SET NOCOUNT ON;

	IF @fin_id1 IS NULL
		SELECT @fin_id1=dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)

	DECLARE @occ1 INT, @paying_id1 INT
    
    DECLARE cur CURSOR LOCAL FOR
    	SELECT P.occ, P.id
    	FROM dbo.PAYINGS p 
		JOIN dbo.OCCUPATIONS o 
			ON p.occ = o.Occ
		WHERE 
			o.tip_id=@tip_id1 
			AND p.fin_id= @fin_id1
    
    OPEN cur
    
    FETCH NEXT FROM cur INTO @occ1, @paying_id1
    
    WHILE @@FETCH_STATUS = 0 BEGIN
		
		IF @debug=1
			PRINT CONCAT('Лицевой: ', @occ1,', Код платежа: ', @paying_id1)

    	EXEC k_pay_cash_update @occ1=@occ1 ,@paying_id1=@paying_id1
    
    	FETCH NEXT FROM cur INTO @occ1, @paying_id1
    
    END
    
    CLOSE cur
    DEALLOCATE cur

END
go

