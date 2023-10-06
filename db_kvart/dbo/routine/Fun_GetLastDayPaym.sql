CREATE   FUNCTION [dbo].[Fun_GetLastDayPaym] (@occ1 int)  
RETURNS smalldatetime AS  
BEGIN 
/*
  Возвращаем дату с последним днем оплаты
*/
   return (   
	   select top 1 p2.day
	   from dbo.Payings as p1
		JOIN dbo.Paydoc_packs as p2 
			ON p1.pack_id=p2.id
	   where p1.occ=@occ1
		 and p2.forwarded=cast(1 as bit)
	   order by p2.day desc
	) 
END
go

