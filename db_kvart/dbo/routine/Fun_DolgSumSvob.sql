CREATE   FUNCTION [dbo].[Fun_DolgSumSvob] (@fin_id SMALLINT,@occ INT)  
RETURNS DECIMAL(9,2)
AS 
 
--
-- Сумма долга когда квартира была пустой вниз от заданного месяца
-- 
-- среди неприватизированных квартир
--  
-- SELECT [dbo].[Fun_DolgSumSvob] (136,700056227) 

BEGIN 
	DECLARE 
	@dolg DECIMAL(9,2)=0, 
	@paid DECIMAL(9,2),
	@fin_id1 SMALLINT,
	@fin_old SMALLINT
	
	DECLARE @t TABLE (fin_id SMALLINT PRIMARY KEY, paid DECIMAL(9,2))

    INSERT INTO @t(fin_id, paid) 
	SELECT o.fin_id, o.PaidAll-o.Paymaccount_ServAll
	FROM dbo.View_OCC_ALL AS o 
	WHERE o.occ=@occ AND fin_id<@fin_id
	AND o.status_id='своб'
	--AND o.proptype_id='непр'
	ORDER BY fin_id DESC
	
	SET @fin_old=@fin_id
	
	DECLARE curs_1 CURSOR LOCAL FOR 
		SELECT fin_id, paid FROM @t ORDER BY fin_id DESC
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @fin_id1,@paid
	WHILE (@@FETCH_STATUS=0)
	BEGIN
		IF @fin_old-@fin_id1<=1 			
			SET @dolg=@dolg+@paid
		ELSE
			BREAK
		SET @fin_old=@fin_id1
		FETCH NEXT FROM curs_1 INTO @fin_id1,@paid
	END
	CLOSE curs_1
	DEALLOCATE curs_1

	
RETURN CASE WHEN @dolg<0 THEN 0 ELSE @dolg END

END
go

