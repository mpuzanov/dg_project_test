CREATE     PROC [dbo].[usp_GMP_Delete] 
@N_EL_NUM varchar(50)
AS 
    SET NOCOUNT ON 

    BEGIN TRAN

    DELETE
    FROM   dbo.GMP
    WHERE  N_EL_NUM = @N_EL_NUM

    COMMIT
go

