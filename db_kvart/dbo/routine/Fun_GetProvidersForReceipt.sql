-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	список исполнителей по дому для ЕПД
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetProvidersForReceipt]
(
@build_id INT
)
RETURNS VARCHAR(2000)
AS
BEGIN
/*
select dbo.Fun_GetProvidersForReceipt(6903) AS Providers
select dbo.Fun_GetProvidersForReceipt(6784) AS Providers

*/

	DECLARE @Result VARCHAR(2000)='';

	WITH cte1 AS (
	SELECT 
		sp.sup_id, s.short_name as serv_name
	From dbo.Paym_list as p
		JOIN dbo.Suppliers as sp ON p.source_id=sp.id
		JOIN dbo.Services as s ON s.id=p.service_id
	WHERE p.build_id=@build_id
		AND ((p.source_id%1000<>0) OR (p.debt+p.penalty_serv+p.penalty_old)<>0)
		AND sp.sup_id>0
	GROUP BY sp.sup_id, s.short_name
	),
	cte2 AS (
	SELECT CASE
               WHEN MAX(COALESCE(sa.synonym_name, '')) <> '' THEN MAX(COALESCE(sa.synonym_name, ''))
               ELSE sa.name
        END AS [name]
		, MAX(COALESCE(sa.adres,'')) as adres
		, MAX(COALESCE(sa.[telefon],'')) as [telefon]
		, MAX(COALESCE(sa.[inn],'')) as [inn]
		, MAX(COALESCE(sa.[ogrn],'')) as [ogrn]
		, MAX(COALESCE(sa.[kpp],'')) as [kpp]
		, MAX(COALESCE(sa.[email],'')) as [email]
		, MAX(COALESCE(sa.[web_site],'')) as [web_site]
		, MAX(COALESCE(sa.[rezhim_work],'')) as [rezhim_work]
		, MAX(COALESCE(ao.[rasschet],'')) as [rasschet]
		, MAX(COALESCE(ao.[bank],'')) as [bank]
		, MAX(COALESCE(ao.[bik],'')) as [bik]
		, MAX(COALESCE(ao.[korschet],'')) as [korschet]
		--, STRING_AGG(CONVERT(VARCHAR(1000), serv_name), ';') AS serv_name  -- sql 2017
		, STUFF(CAST(( 
			SELECT ', ' + t2.serv_name
			FROM cte1 t2
			WHERE t2.sup_id=max(t.sup_id)
			FOR XML PATH(''), TYPE) AS VARCHAR(1000)), 1, 2, '') AS serv_name  -- sql 2016
	From cte1 as t
		JOIN dbo.Suppliers_all as sa ON sa.id=t.sup_id
		LEFT JOIN dbo.Account_org as ao ON sa.bank_account=ao.id
	WHERE sa.adres<>''
	GROUP BY sa.name
	)
	--SELECT * from cte2;
--/*
	SELECT  @Result = STUFF((
		SELECT 
		CONCAT(', ', [name]
		, CASE WHEN adres<>'' THEN CONCAT(', адрес:',adres) ELSE '' END
		, CASE WHEN telefon<>'' THEN CONCAT(', тел:',telefon) ELSE '' END
		, CASE WHEN email<>'' THEN CONCAT(', email:',email) ELSE '' END
		, CASE WHEN web_site<>'' THEN CONCAT(', сайт:',web_site) ELSE '' END
		, CASE WHEN inn<>'' THEN CONCAT(', инн:',inn) ELSE '' END
		, CASE WHEN kpp<>'' THEN CONCAT(', кпп:',kpp) ELSE '' END
		, CASE WHEN rasschet<>'' THEN CONCAT(', р/сч:',rasschet) ELSE '' END
		, CASE WHEN bank<>'' THEN CONCAT(', ',bank) ELSE '' END
		, CASE WHEN bik<>'' THEN CONCAT(', БИК:',bik) ELSE '' END
		, CASE WHEN korschet<>'' THEN CONCAT(', к/сч:',korschet) ELSE '' END
		, CASE WHEN serv_name<>'' THEN CONCAT(', услуги:',serv_name) ELSE '' END
		--, CHAR(10)  -- перенос строки в квитанции
		)
		FROM cte2		
		FOR XML PATH ('')
	), 1, 1, '')
--*/

	RETURN COALESCE(@Result,'');

END
go

