-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_suppliers_tip]
(
	  @tip_id SMALLINT = NULL
	, @only_account_one BIT = 1
)
AS
/*
exec k_suppliers_tip @tip_id=5,@only_account_one=0
exec k_suppliers_tip @tip_id=60,@only_account_one=0
exec k_suppliers_tip @tip_id=28,@only_account_one=0
exec k_suppliers_tip @tip_id=NULL
exec k_suppliers_tip @tip_id=NULL,@only_account_one=0

*/
BEGIN
	SET NOCOUNT ON;

	IF @only_account_one IS NULL
		SET @only_account_one = 1

	IF @tip_id IS NOT NULL
		SELECT vs.id
			 , vs.name
			 , vs.id_accounts
			 , vs.account_one
		FROM dbo.View_suppliers_all vs 
		WHERE (vs.account_one = @only_account_one OR @only_account_one = 0)
			AND EXISTS (
				SELECT 1
				FROM dbo.Occupation_Types ot 
					JOIN dbo.Buildings b ON b.tip_id = ot.id
					JOIN dbo.Build_source bs ON bs.build_id = b.id
					JOIN dbo.Suppliers s ON s.id = bs.source_id
						AND s.service_id = bs.service_id
						AND s.sup_id = vs.id
				WHERE (ot.id = @tip_id OR @tip_id IS NULL)
			)
		UNION ALL
		SELECT 0
			 , 'Без поставщика'
			 , NULL
			 , CAST(0 AS BIT)
		OPTION (RECOMPILE)
	ELSE
		SELECT vs.id
			 , vs.name
			 , vs.id_accounts
			 , vs.account_one
		FROM dbo.View_suppliers_all vs 
		WHERE (vs.account_one = @only_account_one OR @only_account_one = 0)
		UNION ALL
		SELECT 0
			 , 'Без поставщика'
			 , NULL
			 , CAST(0 AS BIT)

END
go

