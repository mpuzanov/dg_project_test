-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[rep_gis_naim_dog]
(
	@tip_id	  SMALLINT = NULL
   ,@build_id INT	   = NULL
   ,@only_new BIT	   = 0  -- только где не заполнено поле id_gis_dog
)
AS
/*
exec rep_gis_naim_dog 1,null,NULL


*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @DB_NAME	 VARCHAR(20) = UPPER(DB_NAME())
		   ,@PROPTYPE_ID VARCHAR(10) = NULL

	IF @only_new IS NULL
		SET @only_new = 0

	IF (@DB_NAME <> 'NAIM'
		AND @tip_id IS NULL)
		SET @tip_id = -1
	IF (@DB_NAME = 'NAIM')
		SELECT
			@PROPTYPE_ID = 'непр'

	SELECT
		rownum = ROW_NUMBER() OVER (ORDER BY build_id, nom_kvr_sort)
	   ,t.*
	   ,p.Last_name AS LastName
	   ,p.First_name AS FirstName
	   ,p.Second_name AS MiddleName
	   ,CASE
			WHEN p.sex = 1 THEN 'м'
			WHEN p.sex = 0 THEN 'ж'
			ELSE NULL
		END AS sex
	   ,p.Birthdate
	   ,p.snils
	   ,DOC.DOCTYPE_ID
	   ,DOC.DOC_NO
	   ,DOC.PASSSER_NO
	   ,DOC.ISSUED

	   ,srok_dok1 = '5'
	   ,srok_dok2 = 'Да'
	   ,srok_paym1 = '10'
	   ,srok_paym2 = 'Да'
	FROM (SELECT
			o.occ
		   ,o.address
		   ,o.PROPTYPE_ID
		   ,b.nom_dom
		   ,CASE
				WHEN LEFT(COALESCE(LTRIM(o.prefix), ''), 1) = '&' THEN REPLACE(o.prefix, '&', '')
				ELSE o.nom_kvr
			END AS nom_kvr
		   ,b.kod_fias
		   --,COALESCE(o.id_nom_gis, '') AS id_nom_gis
		   ,b.adres AS adres_build
		   ,b.id AS build_id
		   ,nom_kvr_sort
		   ,o.fin_id
		FROM dbo.VOCC AS o 
		JOIN dbo.View_BUILDINGS_LITE AS b 
			ON o.build_id = b.id
		JOIN dbo.OCCUPATION_TYPES AS ot 
			ON o.tip_id = ot.id
		WHERE (o.tip_id = @tip_id
		OR @tip_id IS NULL)
		AND (o.build_id = @build_id
		OR @build_id IS NULL)
		AND ot.export_gis = 1
		AND b.kod_fias IS NOT NULL
		AND o.Status_id <> 'закр'
		AND o.Total_sq > 0
		AND b.is_paym_build = 1
		AND (o.PROPTYPE_ID = @PROPTYPE_ID
		OR @PROPTYPE_ID IS NULL)) AS t
	LEFT JOIN dbo.INTPRINT i 
		ON t.occ = i.occ
		AND t.fin_id = i.fin_id
	LEFT JOIN dbo.PEOPLE p 
		ON i.Initials_owner_id = p.id
	LEFT JOIN dbo.IDDOC DOC
		ON DOC.owner_id = p.id
		AND DOC.active = 1
	WHERE (1 = 1)
	ORDER BY build_id, nom_kvr_sort

END
go

