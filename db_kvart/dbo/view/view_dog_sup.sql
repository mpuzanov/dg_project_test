-- dbo.view_dog_sup source

CREATE   VIEW [dbo].[view_dog_sup]
AS
SELECT dbo.DOG_SUP.dog_id, dbo.DOG_SUP.dog_name, dbo.DOG_SUP.dog_date, dbo.DOG_SUP.id AS dog_int, dbo.SUPPLIERS_ALL.name AS sup_name, dbo.VOCC_TYPES.Name AS tip_name, 
       dbo.DOG_SUP.tip_id, dbo.DOG_SUP.sup_id, dbo.DOG_SUP.is_cessia, dbo.DOG_SUP.first_occ, dbo.DOG_SUP.bank_account, dbo.DOG_SUP.id_accounts, dbo.DOG_SUP.date_edit, 
       dbo.DOG_SUP.login_edit, dbo.DOG_SUP.data_start, dbo.DOG_SUP.tip_name_dog, dbo.DOG_SUP.NumberOfDigits, dbo.DOG_SUP.last_occ
	  ,dbo.DOG_SUP.isfirst_occ_added
FROM dbo.DOG_SUP 
INNER JOIN  dbo.VOCC_TYPES ON dbo.DOG_SUP.tip_id = dbo.VOCC_TYPES.id 
INNER JOIN  dbo.SUPPLIERS_ALL ON dbo.DOG_SUP.sup_id = dbo.SUPPLIERS_ALL.id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[35] 4[27] 2[20] 3) )"
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
         Begin Table = "DOG_SUP"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "VOCC_TYPES"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 126
               Right = 455
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SUPPLIERS_ALL"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 245
               Right = 207
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
      Begin ColumnWidths = 19
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_dog_sup'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_dog_sup'
go

