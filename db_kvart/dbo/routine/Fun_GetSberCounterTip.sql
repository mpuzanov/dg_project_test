create   function [dbo].[Fun_GetSberCounterTip](
    @service_id varchar(10)
, @unit_id varchar(10)
)
    returns tinyint
as
begin
    return case
               when @service_id = N'пгаз' and @unit_id = N'кубм' then 1
               when @service_id = N'элек' and @unit_id = N'квтч' then 2
               when @service_id = N'гвод' and @unit_id = N'кубм' then 8
               when @service_id = N'хвод' and @unit_id = N'кубм' then 9
               when @service_id = N'отоп' and @unit_id = N'ггкл' then 10
               else 0
        end
end
go

