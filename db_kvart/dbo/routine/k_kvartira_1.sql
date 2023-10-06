CREATE   PROCEDURE [dbo].[k_kvartira_1]
(
	  @street_id1 INT = NULL
	, @build_id1 INT
)
AS
	/*
		  Спискок квартир по дому
		  exec k_kvartira_1 7,1028
	*/
	SET NOCOUNT ON

	SELECT ROW_NUMBER() OVER (ORDER BY f.nom_kvr_sort) AS ROW_NUM
		 , CAST(
		   CASE
			   WHEN f.Nom_kvr = '' THEN '-'
			   WHEN o.prefix = '&' THEN REPLACE(o.prefix, '&', '-')	-- если только 1 знак
			   WHEN LEFT(o.prefix, 1) = '&' THEN REPLACE(o.prefix, '&', '')   -- если за & ещё что-то есть
			   ELSE SUBSTRING(f.Nom_kvr + COALESCE(o.prefix, ''), 1, 20)
		   END AS VARCHAR(20)) AS Nom_kvr
		 , f.id
		 , f.id AS flat_id
		 , (
			   SELECT COUNT(id)
			   FROM dbo.Counters C 
			   WHERE flat_id = f.id
				   AND C.build_id = @build_id1
				   AND C.date_del IS NULL
		   ) AS Count_counters
		 , (
			   SELECT COUNT(O.Occ)
			   FROM dbo.Occupations AS O 
			   WHERE flat_id = f.id
				   AND O.status_id <> 'закр'
		   ) AS Count_occ
		 , o.Occ AS Occ
	     , o.total_sq as total_sq
		 , o.kol_people AS Count_people
		 , o.status_id AS status_id
		 , o.proptype_id AS proptype_id
		 , f.nom_kvr_sort
		 , o.SaldoAll AS saldo
		 , o.Penalty_old AS penalty
		 , o.PaidAll AS Paid
		 , o.PaymAccount
		 , o.PaymAccount_peny
	FROM dbo.Buildings AS b 
		JOIN dbo.Flats AS f ON b.id = f.bldn_id
		LEFT JOIN dbo.Occupations o ON o.flat_id = f.id
	WHERE b.id = @build_id1
	ORDER BY f.nom_kvr_sort
	OPTION (RECOMPILE)
go

