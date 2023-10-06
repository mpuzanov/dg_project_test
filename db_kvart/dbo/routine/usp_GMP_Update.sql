CREATE       PROC [dbo].[usp_GMP_Update]
@N_EL_NUM varchar(50),
@N_TYPE_STR varchar(50),
@N_STATUS_STR varchar(50),
@N_SUMMA DECIMAL(10, 4),
@ADDRESS varchar(100),
@N_PLAT_NAME varchar(50),
@N_SUMMA_DOLG DECIMAL(10, 4),
@N_UIN varchar(25),
@FILE_NAME varchar(50),
@N_CUID varchar(25),
@N_DATE_PROVODKA smalldatetime,
@N_DATE_PERIOD smalldatetime,
@N_RDATE smalldatetime,
@N_DATE_VVOD smalldatetime,
@date_edit smalldatetime,
@user_edit varchar(50)
AS 
    SET NOCOUNT ON 


    UPDATE dbo.GMP
    SET    N_TYPE_STR = @N_TYPE_STR, N_STATUS_STR = @N_STATUS_STR, N_SUMMA = @N_SUMMA, ADDRESS = @ADDRESS, 
           N_PLAT_NAME = @N_PLAT_NAME, N_SUMMA_DOLG = @N_SUMMA_DOLG, N_UIN = @N_UIN, FILE_NAME = @FILE_NAME, 
           N_CUID = @N_CUID, N_DATE_PROVODKA = @N_DATE_PROVODKA, N_DATE_PERIOD = @N_DATE_PERIOD, N_RDATE = @N_RDATE, 
           N_DATE_VVOD = @N_DATE_VVOD, date_edit = @date_edit, user_edit = @user_edit
    WHERE  N_EL_NUM = @N_EL_NUM
go

