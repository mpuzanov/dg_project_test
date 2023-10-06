CREATE         PROC [dbo].[k_PEOPLE_TmpOutSelect]
	  @occ INT
	, @owner_id INT = NULL
	, @data1 SMALLDATETIME = NULL
AS
	SET NOCOUNT ON

	SELECT pt.[occ]
		 , pt.[owner_id]
		 , pt.[data1]
		 , pt.[data2]
		 , pt.[doc]
		 , pt.[sysuser]
		 , pt.[data_edit]
		 , pt.fin_id
		 , CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') AS Initials
		 , cp.StrFinPeriod AS fin_name
		 , COALESCE((
			   SELECT SUM(Value)
			   FROM dbo.View_added AS ap 
			   WHERE ap.occ = @occ
				   AND ap.add_type = 3
				   AND ap.doc_no = '888'
				   AND ap.fin_id = pt.fin_id
				   AND ap.dsc_owner_id = pt.owner_id
		   ), 0) AS SumAdd
		   , pt.is_noliving
	FROM dbo.People_TmpOut AS pt
		JOIN dbo.Calendar_period cp ON 
			cp.fin_id = pt.fin_id
		JOIN dbo.People p ON 
			pt.owner_id = p.id
	WHERE 
		pt.[occ] = @occ
		AND (pt.[owner_id] = @owner_id OR @owner_id IS NULL)
		AND (pt.[data1] = @data1 OR @data1 IS NULL)
	ORDER BY pt.data_edit DESC
go

