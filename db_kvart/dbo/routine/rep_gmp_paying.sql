-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_gmp_paying] 
(
@fin_id smallint
)
AS
/*
exec rep_gmp_paying 182
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Db_Name VARCHAR(20)= UPPER(DB_NAME())

	--IF @Db_Name<>'NAIM'
	--BEGIN
	--	RAISERROR('Выгрузка только для базы NAIM',16,10)
	--	RETURN 
	--END

	SELECT TOP 5
		2 AS P_TYPE
		,'91111302994040000130' AS P_KBK
		,LTRIM(STR(id)) AS P_NUM
		,[day] AS P_DATE
		,[value] AS P_SUMMA
		,dbo.Fun_Initials(vpl.occ) AS P_PLAT_NAME
	FROM View_payings_lite vpl
	WHERE vpl.fin_id=@fin_id
END
go

