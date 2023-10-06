-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[adm_ssrs_subs_update_to_email]
@SubscriptionID UNIQUEIDENTIFIER
,@ToEmail NVARCHAR(200)
AS
BEGIN
/*
exec adm_ssrs_subs_update_to_email '{FDE71DEA-62D1-49D5-A187-E61B0CA7B0D6}', 'new_email@mail.ru'
*/
	SET NOCOUNT ON;

	DECLARE @myDoc xml

	SELECT @myDoc=CONVERT(XML, sub.ExtensionSettings)
	FROM ReportServer..Subscriptions sub
	WHERE sub.SubscriptionID = @SubscriptionID 
	
	--SELECT @myDoc;

	SET @myDoc.modify('
	replace value of (ParameterValues/ParameterValue[Name=("TO")]/Value/text())[1] with sql:variable("@ToEmail") 
	');
	
	--SELECT @myDoc;

	UPDATE sub 
	SET ExtensionSettings = CAST(@myDoc AS NVARCHAR(MAX) )
	FROM ReportServer..Subscriptions sub
	WHERE sub.SubscriptionID = @SubscriptionID 
END
go

