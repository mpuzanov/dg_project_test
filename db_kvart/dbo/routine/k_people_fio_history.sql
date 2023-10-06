-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_people_fio_history]
(
	  @owner_id INT
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT p.id AS owner_id
		 , t1.id
		 , p.people_uid
		 , t1.date_change
		 , t1.Last_name
		 , t1.First_name
		 , t1.Second_name
		 , t2.Initials
	FROM dbo.Fio_history AS t1
		JOIN dbo.People AS p ON p.id = t1.owner_id
		LEFT JOIN dbo.Users AS t2 ON t1.sysuser = t2.login
	WHERE p.id = @owner_id
	ORDER BY date_change DESC

END
go

