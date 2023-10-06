-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	добавление расчетного счета на лицевой
-- =============================================
CREATE   PROCEDURE [dbo].[k_occ_bankaccount_add]
(
@occ1 INT
,@bank_account1 INT
,@result BIT = 0 OUTPUT -- результат
)
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE o 
	SET bank_account=ao.id
	FROM dbo.Occupations as o
		JOIN dbo.Account_org ao ON ao.id=@bank_account1 AND ao.tip=7
	WHERE o.Occ=@occ1
	IF @@rowcount > 0
		SET @result = 1
END
go

