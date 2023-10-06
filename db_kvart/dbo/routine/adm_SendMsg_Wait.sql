CREATE  PROCEDURE [dbo].[adm_SendMsg_Wait]
AS
--
--  Преверяем есть ли сообщения которые нужно отправить
--
 
--declare @From1 varchar(100), 
--        @To1 varchar(100) ,
--	@Subject1 nvarchar(100),
--	@Body1 varchar(8000),
--	@attachment1 varchar(100) ,
--	@isHTML1 bit
 
--declare curs cursor for 
--  select  from_msg, 
--          to_msg,
--          Subject,
--	  msg,
--	  attachment,
--	  is_HTML
--  from WAITMESSAGE where It_Is_send=0
--open curs
--fetch next from curs into 
--@From1, 
--@To1,
--@Subject1,
--@Body1,
--@attachment1,
--@isHTML1
 
--while (@@fetch_status=0)
--begin
 
--exec sp_send_cdosysmail  @From=@From1, 
--@To=@To1, 
--@Subject=@Subject1, 
--@Body=@Body1, 
--@attachment=@attachment1, 
--@isHTML=@isHTML1
 
--  fetch next from curs into 
--@From1, 
--@To1,
--@Subject1,
--@Body1,
--@attachment1,
--@isHTML1
 
--end
--close curs
--deallocate curs
go

