-- dbo.view_paying_cessia source

CREATE   VIEW [dbo].[view_paying_cessia]
AS
SELECT     dbo.PAYINGS.id, dbo.PAYDOC_PACKS.day, dbo.PAYINGS.value, dbo.PAYING_CESSIA.value_ces, dbo.PAYING_CESSIA.kol_ces, 
                      dbo.PAYING_CESSIA.paymaccount_ces, dbo.PAYING_CESSIA.value_col, dbo.PAYING_CESSIA.kol_col
FROM         dbo.PAYINGS INNER JOIN
                      dbo.PAYING_CESSIA ON dbo.PAYINGS.id = dbo.PAYING_CESSIA.paying_id INNER JOIN
                      dbo.PAYDOC_PACKS ON dbo.PAYINGS.pack_id = dbo.PAYDOC_PACKS.id;
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
         Begin Table = "PAYINGS"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 199
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PAYING_CESSIA"
            Begin Extent = 
               Top = 2
               Left = 527
               Bottom = 164
               Right = 696
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PAYDOC_PACKS"
            Begin Extent = 
               Top = 48
               Left = 336
               Bottom = 203
               Right = 505
            End
            DisplayFlags = 280
            TopColumn = 0
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_paying_cessia'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_paying_cessia'
go

