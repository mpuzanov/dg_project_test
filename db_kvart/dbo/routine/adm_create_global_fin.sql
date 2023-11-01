CREATE   PROCEDURE [dbo].[adm_create_global_fin]
(
	@fin_new SMALLINT
)
AS
	/*
	
	Создаём новый фин период в глобальных таблицах
	
	*/
	SET NOCOUNT ON

	IF EXISTS(SELECT 1 FROM dbo.Global_values WHERE fin_id=@fin_new) -- период уже создан
		RETURN


	DECLARE	@fin_current	SMALLINT
			,@start_date1	SMALLDATETIME
			,@end_date1		SMALLDATETIME
			,@start_date2	SMALLDATETIME
			,@end_date2		SMALLDATETIME

	SELECT
		@fin_current = @fin_new - 1
	SELECT
		@start_date1 = start_date
		,@end_date1 = end_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_current;

	SELECT
		@start_date2 = DATEADD(MONTH, 1, @start_date1)
	SELECT
		@end_date2 = DATEADD(MINUTE, -1, DATEADD(MONTH, 2, @start_date1))

	--********************************************************

	IF NOT EXISTS (SELECT
				1
			FROM dbo.Paycoll_orgs
			WHERE fin_id = @fin_new)
	BEGIN
		INSERT
		INTO dbo.Paycoll_orgs
		(	fin_id
			,bank
			,vid_paym
			,comision
			,ext
			,[description]
			,sup_processing)
			SELECT
				@fin_new
				,bank
				,vid_paym
				,comision
				,ext
				,[description]
				,sup_processing
			FROM dbo.Paycoll_orgs
			WHERE fin_id = @fin_current;

	END
	--********************************************************
	IF NOT EXISTS (SELECT
				1
			FROM [dbo].[Measurement_ee]
			WHERE fin_id = @fin_new)
		INSERT
		INTO [dbo].[Measurement_ee]
		(	fin_id
			,mode_id
			,rooms
			,kol_people
			,kol_watt)
			SELECT
				@fin_new
				,[mode_id]
				,[rooms]
				,[kol_people]
				,[kol_watt]
			FROM [dbo].[Measurement_ee]
			WHERE fin_id = @fin_current;
	--********************************************************
	IF NOT EXISTS (SELECT
				1
			FROM dbo.Global_values
			WHERE fin_id = @fin_new)
	BEGIN

		INSERT
		INTO dbo.Global_values
		(	fin_id
			,start_date
			,end_date
			,StrMes
			,closed
			,ExtSubsidia
			,Mes_nazn
			,SubNorma
			,procent
			,SubClosedData
			,Minzpl
			,Prmin
			,Srok
			,Metod2
			,LiftFloor
			,LiftYear1
			,LiftYear2
			,PenyRas
			,LastPaym
			--,PenyProc
			,PaymClosed
			,PaymClosedData
			,FinClosedData
			,State
			,Region
			,Town
			,Norma1
			,Norma2
			,NormaSub
			,SumLgotaAntena
			,AddGvrProcent
			,AddGvrDays
			,AddOtpProcent
			,POPserver
			,GKAL
			,NormaGKAL
			,StrMes2
			,LgotaRas
			,msg_timeout
			,counter_block_value
			,web_reports
			,filenamearhiv
			,dir_new_version
			,name_org
			,logo
			,basa_name_arxiv
			,profile_mail
			,ProgramName
			,FTPServer
			,FTPUser
			,FTPPswd
			,barcode_type
			,blocked_export
			,KolDayFinPeriod
			,StavkaCB
			,CounterValue1
			,CounterValue2
			,use_koef_build
			,procSubs12
			,settings_json
			,settings_developer
			,heat_summer_start
			,heat_summer_end
			,counter_last_metod)
			SELECT
				@fin_new AS fin_id
				,@start_date2 AS start_date
				,@end_date2 AS end_date
				,'' AS StrMes
				,NULL AS closed
				,ExtSubsidia
				,Mes_nazn
				,SubNorma
				,procent
				,NULL AS SubClosedData
				,Minzpl
				,Prmin
				,Srok
				,Metod2
				,LiftFloor
				,LiftYear1
				,LiftYear2
				,PenyRas
				,LastPaym
				--,PenyProc
				,0 AS PaymClosed
				,null as PaymClosedData
				,NULL AS FinClosedData
				,State
				,Region
				,Town
				,Norma1
				,Norma2
				,NormaSub
				,SumLgotaAntena
				,AddGvrProcent
				,AddGvrDays
				,AddOtpProcent
				,POPserver
				,GKAL
				,NormaGKAL
				,'' AS StrMes2
				,LgotaRas
				,msg_timeout
				,0 AS counter_block_value
				,web_reports
				,filenamearhiv
				,dir_new_version
				,name_org
				,logo
				,basa_name_arxiv
				,profile_mail
				,ProgramName
				,FTPServer
				,FTPUser
				,FTPPswd
				,barcode_type
				,blocked_export
				,DATEDIFF(DAY, @start_date2, DATEADD(MONTH, 1, @start_date2)) AS KolDayFinPeriod
				,StavkaCB
				,CounterValue1
				,CounterValue2
				,use_koef_build
				,procSubs12
				,settings_json
				,settings_developer
				,heat_summer_start
				,heat_summer_end
				,counter_last_metod
			FROM dbo.Global_values
			WHERE fin_id = @fin_current

		UPDATE dbo.Global_values
		SET	StrMes		= lower(DATENAME(MONTH, start_date) + ' ' + DATENAME(YEAR, start_date))
			,StrMes2	= (SELECT
					name_pred
				FROM dbo.View_month
				WHERE id = DATEPART(MONTH, @start_date2))
			+ ' ' + DATENAME(YEAR, @start_date2)
		WHERE fin_id = @fin_new;
	END
go

