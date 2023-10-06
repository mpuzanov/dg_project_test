-- dbo.view_counter_build source

CREATE   VIEW [dbo].[view_counter_build]  AS 
SELECT
	dbo.COUNTERS.is_build
	,dbo.COUNTERS.service_id
	,dbo.COUNTERS.serial_number
	,dbo.COUNTERS.type
	,dbo.COUNTERS.build_id
	,dbo.COUNTERS.max_value
	,dbo.COUNTERS.KOEF
	,dbo.COUNTERS.unit_id
	,dbo.COUNTERS.count_value
	,dbo.COUNTERS.date_create
	,dbo.COUNTERS.CountValue_del
	,dbo.COUNTERS.date_del
	,dbo.COUNTERS.PeriodCheck
	,dbo.COUNTERS.user_edit
	,dbo.COUNTERS.date_edit
	,dbo.COUNTERS.comments
	,dbo.COUNTERS.internal
	,dbo.COUNTERS.checked_fin_id
	,dbo.COUNTERS.id
	,dbo.VSTREETS.name AS street_name
	,dbo.BUILDINGS.nom_dom
	,dbo.BUILDINGS.tip_id
	,dbo.BUILDINGS.nom_dom_sort
	,dbo.BUILDINGS.sector_id
	,dbo.SECTOR.name AS sector_name
FROM dbo.COUNTERS
INNER JOIN dbo.BUILDINGS
	ON dbo.COUNTERS.build_id = dbo.BUILDINGS.id
INNER JOIN dbo.VSTREETS
	ON dbo.BUILDINGS.street_id = dbo.VSTREETS.id
LEFT JOIN dbo.SECTOR 
	ON BUILDINGS.sector_id = dbo.SECTOR.id
WHERE (dbo.COUNTERS.is_build = 1);
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[37] 4[25] 2[20] 3) )"
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
         Begin Table = "COUNTERS"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 230
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "BUILDINGS"
            Begin Extent = 
               Top = 4
               Left = 247
               Bottom = 214
               Right = 424
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "STREETS"
            Begin Extent = 
               Top = 4
               Left = 455
               Bottom = 108
               Right = 624
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
      Begin ColumnWidths = 23
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
         Or', 'SCHEMA', 'dbo', 'VIEW', 'view_counter_build'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N' = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', 'dbo', 'VIEW', 'view_counter_build'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_counter_build'
go

