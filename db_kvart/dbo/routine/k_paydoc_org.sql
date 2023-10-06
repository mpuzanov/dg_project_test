CREATE   PROCEDURE [dbo].[k_paydoc_org]
(
	@is_bank1 SMALLINT = 0
   ,@tip_id	  SMALLINT = NULL
   ,@fin_id	  SMALLINT = NULL 
)
AS
	/*
		Выводим список банков с видами оплат 
		в текущем фин периоде
		
		0 - все
		1 - банки
		2 - взаимозачеты
	
		exec k_paydoc_org @is_bank1=0, @tip_id=28, @fin_id=null
		exec k_paydoc_org 1, 28
		exec k_paydoc_org 2, 28
	*/
	SET NOCOUNT ON

	IF coalesce(@fin_id,0)=0
	begin

		IF @tip_id IS NULL
			SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)
		ELSE
			SELECT
				@fin_id = CASE
					WHEN (ot.ras_paym_fin_new = 1) AND
						 (ot.PaymClosed = 1) THEN ot.fin_id + 1
					ELSE ot.fin_id
                END
		FROM dbo.Occupation_Types AS ot
		WHERE id = @tip_id

	end

	SELECT
		po.id
	   ,CONCAT(po.bank_name , ' (' , RTRIM(po.tip_paym) , ')') as 'name'
	   ,po.bank_name AS short_name
	   ,po.ext
	   ,po.fin_id
	   ,po.peny_no
	   ,po.Bank
	   ,po.is_storno
	FROM dbo.View_paycoll_orgs AS po 
	WHERE po.fin_id = @fin_id
	AND po.is_bank =
		CASE
			WHEN @is_bank1 = 1 THEN 1
			WHEN @is_bank1 = 2 THEN 0
			ELSE po.is_bank
		END
	AND po.visible= CAST(1 AS BIT)
	ORDER BY po.bank_name
go

