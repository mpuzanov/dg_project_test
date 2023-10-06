-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_komp_insert_xml]
	@xml_text NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@iDoc		INT
			,@fin_id	SMALLINT

	SELECT
		@fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DELETE FROM dbo.COMP_SERV_ALL
	WHERE fin_id = @fin_id
	DELETE FROM dbo.COMPENSAC_ALL
	WHERE fin_id = @fin_id

	DROP TABLE IF EXISTS #t1;
	DROP TABLE IF EXISTS #t2;

	EXEC sp_xml_preparedocument	@iDoc OUTPUT
								,@xml_text

	SELECT
		occ
		,dateRaschet
		,dateNazn
		,dateEnd
		,sumkomp
		,sumkvart
		,sumnorm
		,doxod
		,metod
		,kol_people
		,realy_people
		,0 AS koef
		,1 AS avto
		,@fin_id AS finperiod
		,owner_id
		,transfer_bank
		,sum_pm
	INTO #t1
	FROM OPENXML(@iDoc, '/ROOT/COMPENSAC', 2)
	WITH (occ INT '@occ', dateRaschet SMALLDATETIME '@dateRaschet', dateNazn SMALLDATETIME '@dateNazn',
	dateEnd SMALLDATETIME '@dateEnd',
	sumkomp DECIMAL(9, 2) '@sumkomp',
	sumkvart DECIMAL(9, 2) '@sumkvart',
	sumnorm DECIMAL(9, 2) '@sumnorm',
	doxod DECIMAL(9, 2) '@doxod',
	metod TINYINT '@metod',
	kol_people TINYINT '@kol_people',
	realy_people TINYINT '@realy_people',
	owner_id INT '@owner_id',
	transfer_bank BIT '@transfer_bank',
	sum_pm DECIMAL(9, 2) '@sum_pm'
	)

	INSERT INTO dbo.COMPENSAC_ALL
	(	fin_id
		,occ
		,dateRaschet
		,dateNazn
		,dateEnd
		,sumkomp
		,sumkvart
		,sumnorm
		,doxod
		,metod
		,kol_people
		,realy_people
		,koef
		,avto
		,finperiod
		,owner_id
		,transfer_bank
		,sum_pm)
			SELECT
				@fin_id
				,t.occ
				,t.dateRaschet
				,t.dateNazn
				,t.dateEnd
				,t.sumkomp
				,t.sumkvart
				,t.sumnorm
				,t.doxod
				,t.metod
				,t.kol_people
				,t.realy_people
				,0
				,1
				,@fin_id
				,t.owner_id
				,t.transfer_bank
				,t.sum_pm
			FROM #t1 t
			JOIN  dbo.OCCUPATIONS AS o ON t.occ = o.occ

	SELECT
		occ
		,service_id
		,sum1
	INTO #t2
	FROM OPENXML(@iDoc, '/ROOT/COMPENSAC/COMP_SERV', 2)
	WITH (occ INT '../@occ', service_id VARCHAR(10) '@service_id', sum1 DECIMAL(9, 2) '@sum')

	INSERT INTO dbo.COMP_SERV_ALL
	(	fin_id
		,occ
		,service_id
		,tarif
		,value_socn
		,value_paid
		,value_subs
		,subsid_norma)
			SELECT
				@fin_id
				,t2.occ
				,t2.service_id
				,0
				,0
				,0
				,t2.sum1
				,0
			FROM #t2 AS t2
			JOIN dbo.COMPENSAC_ALL AS c 
				ON t2.occ = c.occ
				AND c.fin_id = @fin_id

	DROP TABLE IF EXISTS #t1;
	DROP TABLE IF EXISTS #t2;

	EXEC sp_xml_removedocument @iDoc
END
go

