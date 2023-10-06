CREATE   PROCEDURE [dbo].[k_showPasport]
 AS
set nocount on
 
select * from IDDOC_TYPES order by doc_no, name
go

