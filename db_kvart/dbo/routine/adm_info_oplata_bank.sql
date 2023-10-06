CREATE   PROCEDURE [dbo].[adm_info_oplata_bank]
(
	@fin_id1 SMALLINT
)
AS
	/*		
	Показываем раскидку оплат по банкам и организациям
	в разрезе фин. периода и типа жилого фонда
	
	adm_info_oplata_bank 202
	
	*/
	SET NOCOUNT ON

	SET LANGUAGE Russian

	SELECT
		dbo.Fun_NameFinPeriod(@fin_id1) AS 'Фин_пер'
	   ,ot.name                         AS 'Тип фонда'
	   ,COALESCE(bn.short_name, '????') AS 'Банк'
	   ,SUM(pd.total)                   AS 'sum'
	   , CASE
             WHEN MAX(tt.itog_oplata) > 0 THEN CAST((SUM(pd.total) * 100 / MAX(tt.itog_oplata)) AS DECIMAL(5, 2))
             ELSE 0
        END                             AS Procent
	   , CASE
             WHEN MAX(tt.itog_oplata_tip) > 0
                 THEN CAST((SUM(pd.total) * 100 / MAX(tt.itog_oplata_tip)) AS DECIMAL(5, 2))
             ELSE 0
        END                             AS Procen_tip
	   ,SUM(pd.commission)              AS comission
	   ,MAX(tt.itog_oplata)             AS itog_oplata
	   ,MAX(tt.itog_oplata_tip)         AS itog_oplata_tip
	FROM dbo.PAYDOC_PACKS AS pd 
	JOIN dbo.PAYCOLL_ORGS AS po 
		ON pd.source_id = po.id
	JOIN dbo.BANK AS bn 
		ON po.BANK = bn.id
	JOIN dbo.VOCC_TYPES AS ot
		ON pd.tip_id = ot.id
	JOIN (SELECT
			pd.id
		   ,pd.tip_id
		   ,pd.total
		   ,SUM(pd.total) OVER () AS itog_oplata
		   ,SUM(pd.total) OVER (PARTITION BY pd.tip_id) AS itog_oplata_tip
		FROM dbo.PAYDOC_PACKS AS pd 
		WHERE pd.Fin_id = @fin_id1
		AND pd.forwarded = CAST(1 AS BIT)) tt
		ON pd.id = tt.id
	WHERE pd.forwarded = 1
	AND pd.Fin_id = @fin_id1
	GROUP BY ot.name
			,ot.id
			,bn.short_name
	ORDER BY sum DESC
go

