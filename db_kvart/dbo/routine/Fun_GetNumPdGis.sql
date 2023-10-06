CREATE   FUNCTION [dbo].[Fun_GetNumPdGis]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
RETURNS VARCHAR(18)
AS
BEGIN
/*
	
Функция формирования уникального платёжного документа в ГИС ЖКХ
	
Идентификатор жилищно-коммунальных услуг
+'-'+Посл.цифра года+2 цифры месяц+1 цифра № ПД в периоде

Например: 90ЕТ119242-02-7111 (2017 год, ноябрь, 1 квитанция)

select dbo.Fun_GetNumPdGis(31003,255,null)     -- 60АК152950-01-3041
select dbo.Fun_GetNumPdGis(680000001,190,345)  -- 90ЕТ119242-05-7111
select dbo.Fun_GetNumPdGis(680000001,190,323)  -- 90ЕТ119242-08-7111
*/

DECLARE @id_jku_gis VARCHAR(13), @id_jku_pd_gis VARCHAR(18)

IF COALESCE(@sup_id,0) > 0
	SELECT
		@id_jku_gis = COALESCE(os.id_jku_gis,'')
	FROM dbo.Occ_Suppliers os 
	WHERE os.occ = @occ
	AND os.fin_id = @fin_id
	AND os.sup_id = @sup_id
ELSE
	SELECT
		@id_jku_gis = COALESCE(o.id_jku_gis,'')
	FROM dbo.View_occ_all_lite o 
	WHERE o.occ = @occ
	AND o.fin_id = @fin_id
	
IF @id_jku_gis<>''
	SELECT @id_jku_pd_gis=
		--('%s-%s%02i1', @id_jku_gis,SUBSTRING(DATENAME(YEAR, start_date), 4, 1),MONTH(start_date))
		CONCAT(@id_jku_gis,'-', SUBSTRING(CONVERT(VARCHAR(8), start_date, 112), 4, 3),'1')
	FROM dbo.Global_values gv 
	WHERE gv.fin_id = @fin_id
ELSE
	SET @id_jku_pd_gis=''

RETURN @id_jku_pd_gis	

END
go

