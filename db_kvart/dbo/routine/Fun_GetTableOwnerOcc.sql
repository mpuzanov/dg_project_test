-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetTableOwnerOcc]
(
@occ1 INT
)
/*
select * from dbo.Fun_GetTableOwnerOcc(289015)
*/
RETURNS TABLE
AS
RETURN (
	SELECT p.id
		 , p.occ
		 , p.Last_name
		 , p.First_name
		 , p.Second_name
		 , p.Birthdate
		 , p.email
		 , p.Contact_info
		 , doc.doc_no
		 , doc.passser_no
		 , doc.kod_pvs
	FROM dbo.People AS p 
		LEFT JOIN dbo.Iddoc AS doc ON p.id=doc.owner_id AND doc.active=CAST(1 AS BIT)
	WHERE p.occ = @occ1
		AND p.is_owner_flat = CAST(1 AS BIT)
)
go

