-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[adm_transfer_archive_show]
(
	@Basa	  VARCHAR(20)
   ,@Fin_id	  SMALLINT
   ,@tip_id	  SMALLINT = NULL
   ,@build_id INT	   = NULL
   ,@occ1	  INT	   = NULL
)
/*
exec adm_transfer_archive_show 'kr1',176,28,1031
exec adm_transfer_archive_show 'komp',164,131,NULL
exec adm_transfer_archive_show 'arx_komp',164,131,NULL
*/
AS
BEGIN
	SET NOCOUNT ON;

	IF @occ1 = 0
		SET @occ1 = NULL

	IF @tip_id IS NULL
		AND @build_id IS NULL
		AND @occ1 IS NULL
	BEGIN
		RAISERROR ('Выберите тип фонда или дом или лицевой', 10, 1)
		RETURN
	END

	DECLARE @SQL NVARCHAR(4000)

	SET @SQL =
	'SELECT
		MONTH(start_date) AS Мес
		,SUM(SaldoAll) AS Сальдо
		,SUM(AddedAll) AS Разовые
		,SUM(PaidAll) AS Начисл
		,SUM(Paymaccount_ServAll) AS Оплата								
		,SUM(SaldoAll + PaidAll - Paymaccount_ServAll) AS Кон_сальдо
		,SUM(Penalty_old_new+Penalty_value) AS Пени_итог
		,SUM(SaldoAll + PaidAll - Paymaccount_ServAll + Penalty_old_new + Penalty_value) AS К_Оплате		
		,SUM(kol_people) AS Людей
	FROM  ' + @Basa + '.dbo.View_OCC_ALL AS o	
	WHERE (o.bldn_id = @build_id OR @build_id IS NULL)
	AND (o.occ = @occ1 OR @occ1 IS NULL)
	AND fin_id >= @fin_id
	AND (o.status_id<>''закр'')
	AND (o.tip_id = @tip_id or @tip_id is null)
	GROUP BY start_date ORDER BY start_date'

	PRINT @SQL

	EXECUTE [master].[sys].[sp_executesql] @SQL
										  ,N'@build_id int, @fin_id smallint, @tip_id smallint, @occ1 int'
										  ,@build_id = @build_id
										  ,@Fin_id = @Fin_id
										  ,@tip_id = @tip_id
										  ,@occ1 = @occ1

END
go

