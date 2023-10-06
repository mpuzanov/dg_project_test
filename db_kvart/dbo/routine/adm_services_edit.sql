CREATE   PROCEDURE [dbo].[adm_services_edit]
(
	@id1				  VARCHAR(10)
   ,@name1				  VARCHAR(100)
   ,@short_name1		  VARCHAR(20)
   ,@service_type1		  INT
   ,@is_koef1			  BIT
   ,@is_subsid1			  BIT
   ,@is_norma1			  BIT
   ,@is_counter1		  BIT
   ,@sort_no1			  INT	   = 0
   ,@num_colon1			  SMALLINT = 1
   ,@is_paym1			  BIT	   = 1 -- начислять на услугу
   ,@is_peny1			  BIT	   = 1 -- расчёт пени на услугу
   ,@serv_from			  VARCHAR(100)
   ,@is_build1			  BIT	   = 0 -- для общедомовых нужд (используется совместно с serv_from)
   ,@sort_paym			  SMALLINT = 0
   ,@is_koef_up			  BIT	   = 0
   ,@no_export_volume_gis BIT	   = 0
   ,@unit_id_default	  VARCHAR(10)  = NULL
)
AS
	/*
	  Редактирование услуги
	*/
	SET NOCOUNT ON

	IF @is_build1 = 1
		AND @serv_from = ''
	BEGIN
		RAISERROR ('Если услуга общедомовая - заведите услугу от которой она зависит!', 16, 1)
		RETURN 1
	END

	UPDATE SERVICES 
	SET name				 = LTRIM(RTRIM(@name1))
	   ,short_name			 = LTRIM(RTRIM(@short_name1))
	   ,service_type		 = @service_type1
	   ,is_koef				 = @is_koef1
	   ,is_subsid			 = @is_subsid1
	   ,is_norma			 = @is_norma1
	   ,is_counter			 = @is_counter1
	   ,sort_no				 = @sort_no1
	   ,num_colon			 = @num_colon1
	   ,is_paym				 = @is_paym1
	   ,is_peny				 = @is_peny1
	   ,serv_from			 = @serv_from
	   ,is_build			 = @is_build1
	   ,is_build_serv		 = @serv_from
	   ,sort_paym			 = COALESCE(@sort_paym, 0)
	   ,is_koef_up			 = @is_koef_up
	   ,no_export_volume_gis = @no_export_volume_gis
	   ,unit_id_default		 = @unit_id_default
	WHERE id = @id1
go

