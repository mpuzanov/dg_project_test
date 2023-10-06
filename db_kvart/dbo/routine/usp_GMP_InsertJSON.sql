CREATE         PROC [dbo].[usp_GMP_InsertJSON] (@FileJson NVARCHAR(MAX)
, @msg_out VARCHAR(200) = '' OUTPUT
, @debug BIT = 0)
AS
/*

DECLARE @RC int
DECLARE @FileJson nvarchar(max)
DECLARE @msg_out varchar(200)
DECLARE @debug bit
SET @FileJson =  
N'
{
    "data": [
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": 508,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": 508,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911V301.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-03-31T00:00:00.000Z",
            "n_date_period": "2020-04-14T00:00:00.000Z",
            "n_rdate": "2020-04-14T00:00:00.000Z",
            "n_date_vvod": "2020-04-14T15:00:52.257Z"
        },
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": 0,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": 0,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911U401.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-04-30T00:00:00.000Z",
            "n_date_period": "2020-05-07T00:00:00.000Z",
            "n_rdate": "2020-05-07T00:00:00.000Z",
            "n_date_vvod": "2020-05-08T10:43:02.717Z"
        },
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": 0,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": 0,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911V501.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-05-31T00:00:00.000Z",
            "n_date_period": "2020-06-03T00:00:00.000Z",
            "n_rdate": "2020-06-03T00:00:00.000Z",
            "n_date_vvod": "2020-06-04T15:52:33.303Z"
        },
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": -0.3,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": -0.3,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911U601.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-06-30T00:00:00.000Z",
            "n_date_period": "2020-07-06T00:00:00.000Z",
            "n_rdate": "2020-07-06T00:00:00.000Z",
            "n_date_vvod": "2020-07-06T12:03:50.030Z"
        },
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": 0.3,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": 0.3,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911V701.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-07-31T00:00:00.000Z",
            "n_date_period": "2020-07-31T00:00:00.000Z",
            "n_rdate": "2020-07-31T00:00:00.000Z",
            "n_date_vvod": "2020-09-01T09:34:57.167Z"
        },
        {
            "n_el_num": "0006040002171101",
            "n_type_str": "Сальдо",
            "n_status_str": "Не задана",
            "n_summa": 0.3,
            "address": "г.Ижевск, ул. Ворошилова д.4 кв.4",
            "n_plat_name": "Зубрянкова Т.Е.",
            "n_summa_dolg": 0.3,
            "n_uin": "0320508500060400021905014",
            "file_name": "0911V801.NCH",
            "n_cuid": "0006040002171101",
            "n_date_provodka": "2020-08-31T00:00:00.000Z",
            "n_date_period": "2020-09-02T00:00:00.000Z",
            "n_rdate": "2020-09-02T00:00:00.000Z",
            "n_date_vvod": "2020-09-14T13:33:53.010Z"      
        }
    ]
}'
EXECUTE @RC = [dbo].usp_GMP_InsertJSON 
   @FileJson
  ,@msg_out OUTPUT
  ,@debug=1

SELECT @msg_out
  */
  SET NOCOUNT ON


  -- проверяем файл 
  IF @FileJson IS NULL
    OR ISJSON(@FileJson) = 0
  BEGIN
    SET @msg_out = 'Входной файл не в JSON формате'
    RAISERROR (@msg_out, 10, 1)
    RETURN 0
  END

  DECLARE @user_Initials VARCHAR(50)
         ,@occ INT

  SELECT
    @user_Initials = u.Initials
  FROM USERS u
  WHERE u.login = SYSTEM_USER

  DROP TABLE IF EXISTS #File_TMP

  CREATE TABLE #File_TMP (
   -- id int IDENTITY(1,1),
   N_EL_NUM VARCHAR(50) COLLATE database_default NOT NULL
   ,N_TYPE_STR VARCHAR(50) COLLATE database_default NOT NULL
   ,N_STATUS_STR VARCHAR(50) COLLATE database_default NOT NULL
   ,N_SUMMA DECIMAL(10, 4) NOT NULL
   ,[ADDRESS] VARCHAR(100) COLLATE database_default NOT NULL
   ,N_PLAT_NAME VARCHAR(50) COLLATE database_default NOT NULL
   ,N_SUMMA_DOLG DECIMAL(10, 4) NOT NULL
   ,N_UIN VARCHAR(25) COLLATE database_default NOT NULL
   ,FILE_NAME VARCHAR(50) COLLATE database_default NOT NULL
   ,N_CUID VARCHAR(25) COLLATE database_default NOT NULL
   ,N_DATE_PROVODKA SMALLDATETIME NOT NULL
   ,N_DATE_PERIOD SMALLDATETIME NOT NULL
   ,N_RDATE SMALLDATETIME NOT NULL
   ,N_DATE_VVOD SMALLDATETIME NOT NULL
   ,data_edit SMALLDATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
   ,user_edit NVARCHAR(30) COLLATE database_default
   ,Occ INT
  )

  INSERT #File_TMP (N_EL_NUM
  , N_TYPE_STR
  , N_STATUS_STR
  , N_SUMMA
  , ADDRESS
  , N_PLAT_NAME
  , N_SUMMA_DOLG
  , N_UIN
  , FILE_NAME
  , N_CUID
  , N_DATE_PROVODKA
  , N_DATE_PERIOD
  , N_RDATE
  , N_DATE_VVOD
  , user_edit
  , Occ)
    SELECT
      N_EL_NUM
     ,N_TYPE_STR
     ,N_STATUS_STR
     ,N_SUMMA
     ,ADDRESS
     ,N_PLAT_NAME
     ,N_SUMMA_DOLG
     ,N_UIN
     ,FILE_NAME
     ,N_CUID
     ,N_DATE_PROVODKA
     ,N_DATE_PERIOD
     ,N_RDATE
     ,N_DATE_VVOD
     ,@user_Initials
	 ,CAST(SUBSTRING(N_EL_NUM, 1, 10) AS INT)
    FROM OPENJSON(@FileJson, '$.data')
    WITH (
    N_EL_NUM VARCHAR(50) '$.n_el_num'
    , N_TYPE_STR VARCHAR(50) '$.n_type_str'
    , N_STATUS_STR VARCHAR(50) '$.n_status_str'
    , N_SUMMA DECIMAL(10, 4) '$.n_summa'
    , ADDRESS VARCHAR(100) '$.address'
    , N_PLAT_NAME VARCHAR(50) '$.n_plat_name'
    , N_SUMMA_DOLG DECIMAL(10, 4) '$.n_summa_dolg'
    , N_UIN VARCHAR(25) '$.n_uin'
    , FILE_NAME VARCHAR(50) '$.file_name'
    , N_CUID VARCHAR(25) '$.n_cuid'
    , N_DATE_PROVODKA SMALLDATETIME '$.n_date_provodka'
    , N_DATE_PERIOD SMALLDATETIME '$.n_date_period'
    , N_RDATE SMALLDATETIME '$.n_rdate'
    , N_DATE_VVOD SMALLDATETIME '$.n_date_vvod'
    ) AS t2

	-- оставляем только последнюю запись
    DELETE bdt
	FROM #File_TMP bdt	
	Where bdt.N_DATE_PERIOD not in
	(
		select max(N_DATE_PERIOD) as MaxDATE_PERIOD
		FROM #File_TMP t2
		WHERE t2.N_EL_NUM=bdt.N_EL_NUM
		group by t2.N_EL_NUM
	)

  IF @debug = 1
    SELECT
      *
    FROM #File_TMP bdt	


	DELETE FROM dbo.Gmp

	INSERT into dbo.Gmp(N_EL_NUM
     ,N_TYPE_STR
     ,N_STATUS_STR
     ,N_SUMMA
     ,ADDRESS
     ,N_PLAT_NAME
     ,N_SUMMA_DOLG
     ,N_UIN
     ,FILE_NAME
     ,N_CUID
     ,N_DATE_PROVODKA
     ,N_DATE_PERIOD
     ,N_RDATE
     ,N_DATE_VVOD
	 ,date_edit
	 ,user_edit
	 ,occ
	 )
	SELECT
     N_EL_NUM
     ,N_TYPE_STR
     ,N_STATUS_STR
     ,N_SUMMA
     ,ADDRESS
     ,N_PLAT_NAME
     ,N_SUMMA_DOLG
     ,N_UIN
     ,FILE_NAME
     ,N_CUID
     ,N_DATE_PROVODKA
     ,N_DATE_PERIOD
     ,N_RDATE
     ,N_DATE_VVOD
	 ,data_edit
	 ,user_edit
	 ,occ
    FROM #File_TMP bdt
go

