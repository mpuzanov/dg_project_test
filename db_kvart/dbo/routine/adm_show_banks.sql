CREATE   PROCEDURE [dbo].[adm_show_banks]
(
	@banks BIT = 1	-- только банки
)
AS
	/*
	Показываем список банков или организаций по взаимозачетам
	
	adm_show_banks 1
	adm_show_banks 0
	adm_show_banks NULL
	
	*/

	SET NOCOUNT ON

	SELECT
		0 AS id
	   ,'(ВСЕ)' AS short_name
	   ,'000' AS ext
	UNION ALL
	SELECT
		b.id
	   ,short_name
	   ,ext = COALESCE(vpo.ext, '')
	FROM dbo.BANK AS b
	CROSS APPLY (SELECT TOP 1
			ext
		FROM dbo.View_PAYCOLL_ORGS AS po
		WHERE b.id = po.BANK
		ORDER BY po.fin_id DESC) AS vpo
	WHERE (b.is_bank = @banks
	OR @banks IS NULL)
	ORDER BY short_name
go

