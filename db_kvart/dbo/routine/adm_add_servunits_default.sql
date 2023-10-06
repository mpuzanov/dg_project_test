CREATE   PROCEDURE [dbo].[adm_add_servunits_default]
(
	  @tip_id1 SMALLINT = NULL -- тип жилого фонда  
	  ,@fin_id1 SMALLINT = NULL
)
AS
	/*
	Рекомендуемое первоначальное заполнение единиц измерения услуг по типу фонда
	беруться из таблицы услуг - поле единица измерения по умолчанию
	adm_add_servunits_default 28
	*/

	SET NOCOUNT ON

	IF @fin_id1 IS NULL AND @tip_id1 IS NOT NULL
		SET @fin_id1=dbo.Fun_GetFinCurrent(@tip_id1,NULL,NULL,NULL)
	

	MERGE Service_units AS target USING (
		SELECT COALESCE(@fin_id1, ot.fin_id) AS fin_id
			 , s.id AS service_id
			   --,r.value as roomtype_id
			 , rt.id AS roomtype_id
			 , ot.id
			 , COALESCE(s.unit_id_default, N'един') AS unit_id  -- по умолчанию устанавливаем Единицы потребления
		FROM dbo.Occupation_Types ot
			CROSS JOIN dbo.Services AS s
			CROSS JOIN dbo.Room_types AS rt
		WHERE (ot.id = @tip_id1 OR @tip_id1 IS NULL)
	--and s.unit_id_default is not null
	) AS source
	(fin_id, service_id, roomtype_id, tip_id, unit_id)
	ON (target.fin_id = source.fin_id
		AND target.tip_id = source.tip_id
		AND target.service_id = source.service_id
		AND target.roomtype_id = source.roomtype_id)
	WHEN NOT MATCHED
		THEN INSERT (fin_id
				   , tip_id
				   , service_id
				   , roomtype_id
				   , unit_id)
			VALUES(source.fin_id
				 , source.tip_id
				 , source.service_id
				 , source.roomtype_id
				 , source.unit_id);
	--OUTPUT $ACTION
	--	 , INSERTED.*
	--	 , DELETED.*;
go

