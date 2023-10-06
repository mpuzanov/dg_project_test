-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_gmp_value]
(
	@fin_id	  SMALLINT
   ,@N_STATUS SMALLINT		= -1 -- -1-по умолчанию -- 0-впервые, 3-изменение, 4-удаление
   ,@kol_zap  INT			= NULL
   ,@date_out SMALLDATETIME = NULL -- дата выгрузки (для установки определённой даты (например заранее))
)
AS
/*
exec rep_gmp_value 190,-1,5
exec rep_gmp_value 190

если @N_STATUS=-1 по умолчанию
то если лицевого небыло в прошлом месяце то 0 иначе 3
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Db_Name  VARCHAR(20) = UPPER(DB_NAME())
		   ,@fin_prev SMALLINT

	IF @N_STATUS IS NULL
		SET @N_STATUS = 0
	IF @kol_zap IS NULL
		SET @kol_zap = 9999999

	SET @fin_prev = @fin_id - 1
	IF @date_out IS NULL SET @date_out=dbo.Fun_GetOnlyDate(current_timestamp)


	SELECT TOP (@kol_zap)
		dbo.Fun_GetNumUV_NAIM(o.occ)   -- когда изменение нужен Ноябрь 2017 года
		AS N_EL_NUM  -- Электронный номер начисления
	   ,'04133000690' AS N_BACC  -- Счет бюджета по которому ведется учет начислений   УМЖ было 04133000880 УЖКХ - 04133000690
	   ,'84311109044040012120' AS N_KBK
	   ,'94701000' AS N_OKATO
		/* 
		1 – Начислено, 2 – Начислено пени,3 - Начислено штраф,4 - Скорректировано,5 - Скорректировано пени,
		6 - Скорректировано штраф,7 – Сальдо,8 - Сальдо пени,9 - Сальдо штраф.	
		*/
	   ,'7' AS N_TYPE
		--,dbo.Fun_GetNumUV(i.occ, i.fin_id) AS N_NUM
	   ,'501' AS N_NUM  --	 Номер начисления
	   ,dbo.Fun_GetOnlyDate(dbo.fn_end_month(o.start_date)) AS N_DATE  -- Дата начисления  (последний день периода)
		--,dbo.Fun_GetOnlyDate(i.DateCreate) AS N_RDATE -- Расчетная дата   
	   ,@date_out AS N_RDATE -- дата выгрузки   
		--,(o.saldo + o.Paid+(o.Penalty_old_new+o.Penalty_value)) AS N_SUMMA
	   ,i.SumPaym AS N_SUMMA
	   ,'Плата за наем' AS N_NAZN  -- Назначение начисления
	   ,dbo.Fun_GetAdresFlat(o.flat_id) AS N_PLAT_ADDR
	   ,LTRIM(i.Initials) AS N_PLAT_NAME
	   ,'30e7dd' AS N_DEP_NUM -- Код отдела администратора, который сформировал начисление
	   ,CASE
			WHEN @N_STATUS = -1 AND
			g.occ IS NULL THEN 0      -- впервые
			WHEN @N_STATUS = -1 AND
			i2.occ IS NULL THEN 0      -- впервые
			WHEN @N_STATUS = -1 AND
			i2.occ IS NOT NULL THEN 3  -- был в прошлом месяце
			ELSE @N_STATUS
		END AS N_STATUS   -- Состояние начисления: 0-впервые, 3-изменение, 4-удаление
	   ,dbo.Fun_GetNumUIN_NAIM(o.occ, o.fin_id) AS N_UIN -- Уникальный идентификатор начисления (ГИС ГМП)
	 --,'0100000000009499111111643' AS N_EIP2 --Альтернативный идентификатор плательщика (ГИС ГМП)
	 -- 1-признак ФЗ  01-тип документа  9499111111-серия и номер докумена
	   ,'1010000000009499111111' AS N_EIP2 --201910 Альтернативный идентификатор плательщика (ГИС ГМП)
	   ,'643' AS N_CITIZENSHIP	-- Числовой код страны согласно общероссийскому классификатору стран мира.
	   ,'01' AS N_DOC_TYPE	-- Код типа документа, удостоверяющего личность.
	   ,'9499111111' AS N_DOC_NUM	-- Номер документа, удостоверяющего личность 
	FROM View_OCC_ALL_LITE o 
	JOIN INTPRINT i 
		ON o.occ = i.occ
		AND o.fin_id = i.fin_id
	JOIN Buildings b 
		ON o.bldn_id = b.id
	JOIN Streets s 
		ON b.street_id = s.id
	LEFT JOIN Intprint i2 
		ON o.occ = i2.occ
		AND i2.fin_id = @fin_prev
	LEFT JOIN (SELECT DISTINCT
			occ
		FROM GMP) AS g
		ON o.occ = g.occ
	WHERE 
		o.fin_id = @fin_id
		--AND (o.saldo + o.Paid + (o.Penalty_old_new + o.Penalty_value) > 0)
		AND o.status_id <> 'закр'
		AND o.total_sq > 0
		AND o.proptype_id = 'непр'
	ORDER BY s.Name, b.nom_dom_sort, o.nom_kvr_sort

END
go

