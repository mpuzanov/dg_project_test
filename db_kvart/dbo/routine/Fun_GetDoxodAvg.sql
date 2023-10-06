-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetDoxodAvg] (@owner_id  int)
RETURNS decimal(15,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE  @doxod_avg decimal(15,2)

	select @doxod_avg=doxod/KolMesDoxoda
	from people as p,
		person_statuses as ps
	Where p.id=@owner_id 
      and p.status2_id=ps.id
      and ps.is_subs=1
      and p.Del=0
      and doxod>0
      and KolMesDoxoda>0
	-- Return the result of the function
	RETURN @doxod_avg

END
go

