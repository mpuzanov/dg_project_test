-- dbo.view_counter_inspector source

-- dbo.view_counter_inspector source

CREATE   VIEW [dbo].[view_counter_inspector]  AS 
SELECT 
	ci.counter_id
	,ci.fin_id
	,vca.occ
	,ci.id
	,ci.inspector_value
	,ci.tip_value
	,ci.inspector_date
	,ci.actual_value
	,ci.kol_day
	,ci.value_vday
	,ci.value_paym
	,ci.tarif
	,ci.mode_id
	,ci.comments
	,ci.date_edit
	,ci.metod_input	
	,ci.user_edit
	,ci.warning
	,ci.metod_rasch
	,vca.service_id
	,vca.internal
	,vca.address
	,dbo.USERS.Initials
	,vca.bldn_id
	,vca.flat_id
	,vca.KolmesForPeriodCheck
	,vca.id_pu_gis
	,vca.unit_id
	,vca.tip_id
	,vca.tip_name
FROM dbo.Counter_inspector AS ci
INNER JOIN dbo.View_counter_all	AS vca
	ON ci.counter_id = vca.counter_id
	AND ci.fin_id = vca.fin_id
LEFT OUTER JOIN dbo.Users
	ON ci.user_edit = dbo.Users.id;
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
         Begin Table = "COUNTER_INSPECTOR"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 250
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "View_COUNTER_ALL"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 125
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 10
         End
         Begin Table = "USERS"
            Begin Extent = 
               Top = 126
               Left = 245
               Bottom = 245
               Right = 417
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_counter_inspector'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_counter_inspector'
go

