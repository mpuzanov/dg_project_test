-- dbo.vocc_suppliers source

CREATE   VIEW [dbo].[vocc_suppliers]
AS
SELECT        
fin_id
, occ
, sup_id
, occ_sup
, saldo
, value
, added
, paid
, paymaccount
, paymaccount_peny
, penalty_calc
, penalty_old_edit
, penalty_old
, penalty_old_new
, penalty_added
, penalty_value
, kolmesdolg
, debt
, paid_old
, dog_int
, cessia_dolg_mes_old
, cessia_dolg_mes_new
, case 
	when (((saldo+paid)-(paymaccount-paymaccount_peny))+((penalty_value+penalty_added)+penalty_old_new))<0
	then 0
	else ((saldo+paid)-(paymaccount-paymaccount_peny))+((penalty_value+penalty_added)+penalty_old_new) 
end
as whole_payment

,case 
	when (((saldo+paid)-(paymaccount-paymaccount_peny))+((penalty_value+penalty_added)+penalty_old_new))>=0
	then 0
	else ((saldo+paid)-(paymaccount-paymaccount_peny))+((penalty_value+penalty_added)+penalty_old_new) 
end
as whole_payment_minus
, (paymaccount-paymaccount_peny) AS paymaccount_serv
, id_jku_gis
, rasschet
, occ_sup_uid
, schtl_old
, ((penalty_old_new+penalty_added)+penalty_value) AS debt_peny
, paymaccount_storno
, qrdata

FROM  dbo.Occ_Suppliers as os;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Occ_Suppliers"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 334
               Right = 241
            End
            DisplayFlags = 280
            TopColumn = 16
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', 'dbo', 'VIEW', 'vocc_suppliers'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'vocc_suppliers'
go

