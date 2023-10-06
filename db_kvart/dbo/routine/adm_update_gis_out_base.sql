-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[adm_update_gis_out_base]
(
	@db_name	   VARCHAR(30) -- база, в которой надо обновить параметры выгрузки в гис
   ,@debug		   BIT		= 0
   ,@KolUpdate	   SMALLINT = 0 OUTPUT -- кол-во обновлённых параметров
   ,@KolUpdateFile SMALLINT = 0 OUTPUT -- кол-во обновлённых шаблонов
)
AS
/*

adm_update_gis_out_base 'kvart',1

declare @KolUpdate	SMALLINT
exec adm_update_gis_out_base @db_name='kvart',@debug=0,@KolUpdate=@KolUpdate OUT
select @KolUpdate
*/
BEGIN

	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(4000)
	DECLARE @DB_NAME_CURRENT VARCHAR(20) = UPPER(DB_NAME())

	IF @db_name <> @DB_NAME_CURRENT
	BEGIN

		SET @SQL =
		'MERGE
		INTO ' + @db_name + '.dbo.GIS_SHABLONS AS Target USING (SELECT
				t2.id
			   ,t2.name
			   ,t2.comments
			   ,t2.FileName
			   ,t2.FileDateEdit
			   ,t2.REPORT_BODY
			   ,t2.Versia
			   ,t2.VersionInt
			   ,t2.UserEdit
			FROM ' + @DB_NAME_CURRENT + '.dbo.GIS_SHABLONS AS t2) AS Source
		ON Target.id = Source.id
		WHEN MATCHED
			THEN UPDATE
				SET comments = Source.comments
				,FileName = Source.FileName
			    ,FileDateEdit = Source.FileDateEdit
			    ,REPORT_BODY = Source.REPORT_BODY
			    ,Versia = Source.Versia
			    ,VersionInt = Source.VersionInt
			    ,UserEdit = Source.UserEdit
		WHEN NOT MATCHED BY Target
			THEN INSERT
				(id
				,name
				,comments
				,FileName
			    ,FileDateEdit
			    ,REPORT_BODY
			    ,Versia
			    ,VersionInt
			    ,UserEdit)
				VALUES 
				(id
				,name
				,comments
				,FileName
			   ,FileDateEdit
			   ,REPORT_BODY
			   ,Versia
			   ,VersionInt
			   ,UserEdit);
		SET @KolUpdateFile=@@ROWCOUNT'

		IF @debug = 1
			PRINT @SQL
		ELSE
			EXECUTE master.sys.sp_executesql @SQL
											,N'@KolUpdateFile smallint OUTPUT'
											,@KolUpdateFile = @KolUpdateFile OUTPUT


		SET @SQL =
		'MERGE
		INTO ' + @db_name + '.dbo.GIS_OUT AS Target USING (SELECT
				t2.shablon_id
			   ,t2.versia
			   ,t2.num_list			   
			   ,t2.num_col
			   ,t2.field_name
			FROM ' + @DB_NAME_CURRENT + '.dbo.GIS_OUT AS t2) AS Source
		ON Target.shablon_id = Source.shablon_id
			AND Target.versia = Source.versia
			AND Target.num_list = Source.num_list
			AND Target.num_col = Source.num_col
		WHEN MATCHED
			THEN UPDATE
				SET field_name = Source.field_name
		WHEN NOT MATCHED BY Target
			THEN INSERT
				(shablon_id
				,versia
				,num_list
				,num_col
				,field_name)
				VALUES (shablon_id
					   ,versia
					   ,num_list
					   ,num_col
					   ,field_name);
		SET @KolUpdate=@@ROWCOUNT'


		IF @debug = 1
			PRINT @SQL
		ELSE
			EXECUTE master.sys.sp_executesql @SQL
											,N'@KolUpdate smallint OUTPUT'
											,@KolUpdate = @KolUpdate OUTPUT
	END
	SELECT
		COALESCE(@KolUpdate, 0)
/*							
SELECT r.shablon_id, r.versia, r.num_list, r.field_name, r.num_col
--UPDATE r2 set r2.REPORT_BODY=r.REPORT_BODY,r2.FileDateEdit=r.FileDateEdit
FROM dbo.GIS_OUT r 
JOIN kvart.dbo.GIS_OUT r2 ON r.shablon_id=r2.shablon_id
WHERE r.FileName<>'' AND r.FileDateEdit>r2.FileDateEdit
ORDER BY r.FileName
*/
END
go

