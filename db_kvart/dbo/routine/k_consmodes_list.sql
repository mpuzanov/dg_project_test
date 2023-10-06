CREATE   PROCEDURE [dbo].[k_consmodes_list]
(
	@occ1   INT = 0
   ,@filter BIT = 0
)
AS
	/*
		Показываем режимы потребления и поставщиков
		на лицевом счете

	exec k_consmodes_list 910010129
	exec k_consmodes_list 910010129, 1
	*/
	SET NOCOUNT ON;

	SELECT
		s.id
	   ,s.short_name AS [name]
	   ,c.occ
	   ,c.service_id
	   ,c.sup_id
	   ,c.mode_id
	   ,c.source_id
	   ,c.koef
	   ,c.subsid_only
	   ,c.is_counter
	   ,CASE
			WHEN c.is_counter = 1 THEN 'внешний'
			WHEN c.is_counter = 2 THEN 'внутрен.'
			ELSE NULL
		END AS counter_type
	   ,c.account_one
	   ,c.lic_source
	   ,c.occ_serv
	   ,occ_serv_kol
	   ,CAST(date_start AS SMALLDATETIME) AS date_start
	   ,CAST(date_end AS SMALLDATETIME) AS date_end
	FROM dbo.Consmodes_list AS c 
	JOIN dbo.View_services AS s
		ON c.service_id = s.id
	WHERE c.occ = @occ1
	AND (@filter = 0 
		OR (@filter = 1
			AND (
				(c.mode_id % 1000) != 0
				OR (c.source_id % 1000) != 0
				OR koef IS NOT NULL
				OR subsid_only <> 0
				OR c.is_counter > 0
				OR c.sup_id > 0
				OR (c.lic_source <> '')
				)
			)
	)
	ORDER BY s.short_name;
go

