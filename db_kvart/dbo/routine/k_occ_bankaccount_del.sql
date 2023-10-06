-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	очистить расчетный счет на лицевом
-- =============================================
CREATE   PROCEDURE [dbo].[k_occ_bankaccount_del]
(
@occ1 INT
,@result BIT = 0 OUTPUT -- результат
)
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE o 
	SET bank_account=NULL
	FROM dbo.Occupations as o
	WHERE o.Occ=@occ1
	IF @@rowcount > 0
		SET @result = 1
END
go

