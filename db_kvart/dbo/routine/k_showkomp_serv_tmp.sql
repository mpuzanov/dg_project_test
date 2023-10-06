CREATE   PROCEDURE [dbo].[k_showkomp_serv_tmp] 
( @occ1 INT)
AS
 
SET NOCOUNT ON
 
SELECT s.short_name, c.tarif, 
       c.value_socn, c.value_paid, c.value_subs, c.subsid_norma,
       'value'=pl.value  ---pl.discount
FROM dbo.comp_SERV_tmp AS c  
     JOIN dbo.View_SERVICES AS s ON c.service_id=s.id
     JOIN dbo.paym_list AS pl ON c.occ=pl.occ AND c.service_id=pl.service_id
WHERE c.occ=@occ1   
ORDER BY s.sort_no
go

