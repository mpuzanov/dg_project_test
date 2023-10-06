CREATE   FUNCTION [dbo].[Fun_GetNumPdGis2]
(
	@id_jku_gis VARCHAR(13)
	,@fin_id smallint
)
RETURNS VARCHAR(18)
AS
BEGIN
	/*
	
	Функция формирования уникального платёжного документа в ГИС ЖКХ
	
	Идентификатор жилищно-коммунальных услуг
	+'-'+Посл.цифра года+2 цифры месяц+1 цифра № ПД в периоде

	Например: 90ЕТ119242-02-7111 (2017 год, ноябрь, 1 квитанция)

	select dbo.Fun_GetNumPdGis2('80ЕТ104262-05',190)  -- 80ЕТ104262-05-7111

	*/

	DECLARE @id_jku_pd_gis VARCHAR(18)
	
	IF @id_jku_gis<>''
		SELECT @id_jku_pd_gis=
			--('%s-%s%02i1', @id_jku_gis, SUBSTRING(DATENAME(YEAR, start_date), 4, 1),MONTH(start_date))
			CONCAT(@id_jku_gis,'-', SUBSTRING(CONVERT(VARCHAR(8), start_date, 112), 4, 3),'1')
		FROM dbo.Global_values gv
		WHERE gv.fin_id = @fin_id
	ELSE
		SET @id_jku_pd_gis=''

	RETURN @id_jku_pd_gis	

END
go

