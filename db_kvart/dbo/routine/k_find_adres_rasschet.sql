-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Поиск адреса по расч.счёту
-- =============================================
CREATE   PROCEDURE [dbo].[k_find_adres_rasschet]
(
	@rasschet	VARCHAR(20)
	,@RowCount	INT	= 0 OUTPUT
)
AS
BEGIN
/*
	exec k_find_adres_rasschet '40705810968000093308'

	declare @RowCount	INT
	exec k_find_adres_rasschet @rasschet='40705810768000000517', @RowCount=@RowCount OUT
	select @RowCount
*/
	SET NOCOUNT ON;

	-- поиск адреса по расч.счёту
	SELECT DISTINCT
		vb.adres
		,os.rasschet
		,sup_name=sa.name
	FROM dbo.OCC_SUPPLIERS os
	JOIN dbo.View_OCC_ALL_LITE o 
		ON os.OCC = o.OCC
		AND os.fin_id = o.fin_id
	JOIN dbo.View_BUILDINGS vb 
		ON o.bldn_id = vb.id
		AND o.fin_id = vb.fin_current
	JOIN dbo.SUPPLIERS_ALL sa 
		ON os.sup_id = sa.id
	WHERE os.rasschet = @rasschet	
	SET @RowCount=@@rowcount
	
END
go

