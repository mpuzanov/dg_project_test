-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_penalty_added_del]
 @occ_peny INT,
 @fin_id1 SMALLINT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @occ1 INT

	SELECT @occ1=occ
	FROM dbo.Occupations 
	WHERE occ=@occ_peny

	IF @occ1 IS NULL
		SELECT TOP (1) @occ1=occ
		FROM dbo.Occ_Suppliers 
		WHERE occ_sup=@occ_peny

	IF dbo.Fun_AccessPenaltyLic(@occ1) = 0
	BEGIN
		RAISERROR (N'Работа с пени Вам запрещена', 16, 1, @occ1)
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		RAISERROR (N'Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
	END

	DECLARE @fin_current SMALLINT = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @fin_id1=@fin_current AND @occ1>0
		DELETE FROM dbo.Peny_added
		WHERE fin_id = @fin_id1
			AND Occ = @occ_peny
END
go

