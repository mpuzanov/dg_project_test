CREATE   FUNCTION [dbo].[Fun_TallyGenerator] (
	 @StartValue bigint=-32768, 
     @EndValue bigint= 32767, 
	 @Rows INT = 1000000 , -- number of rows to be returned. Used only when either @StartValue or @EndValue is not supplied
     @Increment smallint=1
	)
RETURNS TABLE
/*
Use cases:

Sequential numbers from 1 to 100, step 1:

select N 

from dbo.TallyGenerator (1,100, null, 1)
100 sequential numbers starting from 15 , step 1:
select N 
from dbo.TallyGenerator (15,null, 100, 1)
Counting down from 100 to 1, step 11:
select N 
from dbo.TallyGenerator (100,1, null, -11)
Top 100 numbers less or equal 256:
select N 
from dbo.TallyGenerator (256, null, 100,-1)
*/
AS RETURN
(
	with BaseNum (N) as (
		 select 1 union all select 1 union all select 1 union all select 1 union all select 1 union all
		 select 1 union all select 1 union all select 1 union all select 1 union all select 1
		 ),
		 L1 (N) as (
			 select bn1.N
			 from BaseNum bn1
				 cross join BaseNum bn2),
		 L2 (N) as (
			 select top ( coalesce(abs( @EndValue - @StartValue) /abs(@Increment)+ 1, @Rows))
				 a1.N
			 from L1 a1
				 cross join L1 a2),
		 L3 (N) as (
			 select top (coalesce(abs( @EndValue - @StartValue) /abs(@Increment)+ 1, @Rows) )
				 a1.N 
			 FROM L2 a1 
				 cross join L2 a2 
				 cross join L2 a3 
			 ),
		 Tally (N, Increment) as (
			 SELECT row_number() over (order by a1.N), coalesce(SIGN(@EndValue - @StartValue), SIGN(@Increment)) * ABS (@Increment)
			 FROM L3 a1
			 )
		 SELECT ((N - 1) * Increment) + coalesce(@StartValue, @EndValue - @Rows*@Increment + 1)  as N 
		 FROM Tally
)
go

