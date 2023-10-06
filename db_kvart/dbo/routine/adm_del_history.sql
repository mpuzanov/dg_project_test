CREATE   PROCEDURE [dbo].[adm_del_history]
(
	@year_old_del SMALLINT = 10 -- удалять старше чем @year_old_del лет
)
AS
	/*
		Удалять информацию старше 5 лет, а для некоторых 4 года
		Пузанов
		
		adm_del_history 7
		
	*/

	--SET NOCOUNT ON

	DECLARE	@Fin_id1		SMALLINT
			,@end_date		SMALLDATETIME
			,@Fin_id4		SMALLINT
			,@end_date4		SMALLDATETIME
			,@RowsDeleted	INT

	IF @year_old_del IS NULL
		SET @year_old_del = 6

	-- данные старше @year_old_del лет
	SELECT
		@end_date = DATEADD(YEAR, -@year_old_del, current_timestamp)
	--  Возвращаем дату с первым денем месяца
	SET @end_date = dbo.Fun_GetOnlyDate(DATEADD(DAY, 1 - DAY(@end_date), @end_date))
	PRINT @end_date
	SELECT
		@Fin_id1 = fin_id
	FROM dbo.GLOBAL_VALUES AS gb 
	WHERE gb.start_date = @end_date
	PRINT @Fin_id1

	-- данные старше @year_old_del(с начала след года) лет
	SELECT
		@end_date4 = CAST((YEAR(current_timestamp) - (@year_old_del - 1)) AS CHAR(4)) + '0101'
	--set @end_date4=dbo.Fun_GetOnlyDate(dateadd(day,1-day(@end_date4),@end_date4))
	PRINT @end_date4
	SELECT
		@Fin_id4 = fin_id
	FROM dbo.GLOBAL_VALUES AS gb 
	WHERE gb.start_date = @end_date4
	PRINT @Fin_id4

	--RETURN

	--select t.* from OP_LOG as t where done<@end_date
	RAISERROR ('DELETE OP_LOG', 10, 1) WITH NOWAIT;
	DELETE FROM dbo.OP_LOG
	WHERE done < @end_date4

	--select t.* from BANK_DBF as t where PDATE<@end_date
	RAISERROR ('DELETE BANK_DBF', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM BANK_DBF WHERE id IN (SELECT top (10000) id FROM BANK_DBF WHERE PDATE < @end_date4)

		SET @RowsDeleted = @@rowcount
	END	

	--select * from BANK_TBL_SPISOK where DataVvoda<@end_date
	RAISERROR ('DELETE BANK_TBL_SPISOK', 10, 1) WITH NOWAIT;
	DELETE bts
	FROM dbo.Bank_tbl_spisok as bts
	WHERE DataVvoda < @end_date4
		AND NOT EXISTS(SELECT * FROM Bank_Dbf as bd where bd.filedbf_id=bts.filedbf_id)

	RAISERROR ('DELETE Paying_serv', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
	
		DELETE ps 
		FROM dbo.Paying_serv as ps 
		    JOIN dbo.Payings as p ON 
				ps.paying_id = p.id
		WHERE p.id in (SELECT TOP (10000) id FROM Payings WHERE fin_id < @Fin_id4)
			
		SET @RowsDeleted = @@rowcount
	END	

	RAISERROR ('DELETE Payings', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM Payings WHERE id in (SELECT TOP (10000) id FROM Payings WHERE fin_id < @Fin_id4)
		
		SET @RowsDeleted = @@rowcount
	END	

	RAISERROR ('DELETE Paydoc_packs', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM Paydoc_packs WHERE id IN (SELECT TOP (10000) id FROM Paydoc_packs WHERE fin_id < @Fin_id4)
		
		SET @RowsDeleted = @@rowcount
	END	

	--select t.* from PAYM_HISTORY as t where t.fin_id<@Fin_id1
	RAISERROR ('DELETE PAYM_HISTORY', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM PAYM_HISTORY
		WHERE fin_id < @Fin_id4
			AND occ IN (SELECT TOP (1000) occ FROM PAYM_HISTORY WHERE fin_id < @Fin_id4)
		
		SET @RowsDeleted = @@rowcount
	END

	-- Уменьшаем физический размер файла
	--DBCC SHRINKFILE (komp_data)
	--DBCC SHRINKFILE (komp_log, 2)

	--select t.* from CONSMODES_HISTORY as t where t.fin_id<@Fin_id1
	RAISERROR ('DELETE CONSMODES_HISTORY', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM CONSMODES_HISTORY
		WHERE fin_id < @Fin_id4
			AND occ IN (SELECT TOP (1000) occ FROM CONSMODES_HISTORY WHERE fin_id < @Fin_id4)

		SET @RowsDeleted = @@rowcount
	END

	--select t.* from INTPRINT as t where t.fin_id<@Fin_id1
	RAISERROR ('DELETE INTPRINT', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM INTPRINT
		WHERE fin_id < @Fin_id4
			AND occ IN (SELECT TOP (1000) occ FROM INTPRINT WHERE fin_id < @Fin_id4)

		SET @RowsDeleted = @@rowcount
	END

	--select t.* from COMP_SERV_HISTORY as t where t.fin_id<@Fin_id1
	RAISERROR ('DELETE COMP_SERV_ALL', 10, 1) WITH NOWAIT;
	DELETE FROM dbo.COMP_SERV_ALL
	WHERE fin_id < @Fin_id4

	RAISERROR ('DELETE COMPENSAC_ALL', 10, 1) WITH NOWAIT;
	DELETE FROM dbo.COMPENSAC_ALL
	WHERE fin_id < @Fin_id4

	RAISERROR ('DELETE ADDED_PAYMENTS_HISTORY', 10, 1) WITH NOWAIT;
	SET @RowsDeleted = 1
	WHILE (@RowsDeleted > 0)
	BEGIN
		DELETE FROM ADDED_PAYMENTS_HISTORY WHERE id IN (SELECT TOP (10000) id FROM ADDED_PAYMENTS_HISTORY WHERE fin_id < @Fin_id4)

		SET @RowsDeleted = @@rowcount
	END

	-- Уменьшаем физический размер файла
	--DBCC SHRINKFILE (komp_data)
	--DBCC SHRINKFILE (komp_log, 2)

	DELETE FROM dbo.PAYM_LGOTA_ALL
	WHERE fin_id < @Fin_id4
	--RAISERROR ('DELETE PAYCOLL_ORGS', 10, 1) WITH NOWAIT;
	--DELETE FROM dbo.PAYCOLL_ORGS
	--WHERE fin_id < @Fin_id1
	DELETE FROM dbo.PAYM_COUNTER_ALL
	WHERE fin_id < @Fin_id1
	DELETE FROM dbo.COUNTER_PAYM2
	WHERE fin_id < @Fin_id1
	RAISERROR ('DELETE COUNTER_LIST_ALL', 10, 1) WITH NOWAIT;
	DELETE FROM dbo.COUNTER_LIST_ALL
	WHERE fin_id < @Fin_id1
	DELETE FROM dbo.BUILDINGS_HISTORY
	WHERE fin_id < @Fin_id1
	--delete from dbo.occ_HISTORY where fin_id<@fin_id1
	RAISERROR ('DELETE PENY_all', 10, 1) WITH NOWAIT;
	DELETE FROM dbo.PENY_all
	WHERE fin_id < @Fin_id1
	DELETE FROM dbo.PENY_DETAIL
	WHERE fin_id < @Fin_id1

	RAISERROR ('DELETE MEASUREMENT_UNITS', 10, 1) WITH NOWAIT;
	DELETE FROM MEASUREMENT_UNITS WHERE fin_id < @Fin_id1

	RAISERROR ('DELETE DOM_SVOD_ALL', 10, 1) WITH NOWAIT;
	DELETE FROM DOM_SVOD_ALL WHERE fin_id < @Fin_id1
go

