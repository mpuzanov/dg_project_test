-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[k_print_group_show]
(
	@OrdSeq TINYINT = 2
)
AS
BEGIN
	/*
	k_print_group_show
	k_print_group_show 1
	k_print_group_show 2
	k_print_group_show 3
	k_print_group_show 4
	*/
	SET NOCOUNT ON;

	IF @OrdSeq IS NULL
		SET @OrdSeq = 2

	SELECT
		pg.id
	   ,pg.name
	   ,pg.comments
	   ,pg.print_only_group
	   ,t_count_occ.count_occ AS count_occ
	FROM dbo.PRINT_GROUP pg 
	CROSS APPLY (SELECT
			COUNT(po.occ) AS count_occ
		FROM PRINT_OCC po 
		JOIN dbo.OCCUPATIONS AS o 
			ON po.occ = o.occ
		WHERE po.group_id = pg.id
		AND o.STATUS_ID <> 'закр'
		AND o.TOTAL_SQ > 0) AS t_count_occ
	ORDER BY CASE @OrdSeq
		WHEN 1 THEN id
		ELSE NULL
	END,
	CASE @OrdSeq
		WHEN 2 THEN name
		ELSE NULL
	END asc,
	CASE @OrdSeq
		WHEN 3 THEN comments
		ELSE NULL
	END,
	CASE @OrdSeq
		WHEN 4 THEN count_occ
		ELSE NULL
	END
END
go

