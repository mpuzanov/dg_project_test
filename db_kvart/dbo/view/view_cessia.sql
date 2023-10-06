-- dbo.view_cessia source

CREATE   view [dbo].[view_cessia]
as
select
	dbo.cessia.occ_sup
	,dbo.cessia.dolg_mes_start
	,dbo.cessia.cessia_dolg_mes_new
	,dbo.cessia.occ
	,dbo.cessia.dog_int
	,dbo.cessia.saldo_start
	,dbo.dog_sup.dog_name
	,dbo.dog_sup.dog_id
	,dbo.flats.bldn_id
	,dbo.occupations.address
	,dbo.dog_sup.sup_id
	,dbo.dog_sup.tip_id
	,dbo.occupation_types.name as tip_name
	,dbo.view_buildings.street_name
	,dbo.view_buildings.nom_dom
	,dbo.flats.nom_kvr
	,dbo.dog_sup.dog_date
	,dbo.dog_sup.data_start
	,dbo.cessia.debt_current
	,dbo.dog_sup.is_cessia
from dbo.cessia
inner join dbo.occupations
	on dbo.cessia.occ = dbo.occupations.occ
inner join dbo.flats
	on dbo.occupations.flat_id = dbo.flats.id
inner join dbo.occupation_types
	on dbo.occupations.tip_id = dbo.occupation_types.id
left outer join dbo.dog_sup
	on dbo.occupation_types.id = dbo.dog_sup.tip_id
	and dbo.cessia.dog_int = dbo.dog_sup.id
inner join dbo.view_buildings
	on dbo.flats.bldn_id = dbo.view_buildings.id
where (dbo.dog_sup.is_cessia = 1);
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[47] 4[16] 2[11] 3) )"
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
         Begin Table = "CESSIA"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 233
            End
            DisplayFlags = 280
            TopColumn = 5
         End
         Begin Table = "OCCUPATIONS"
            Begin Extent = 
               Top = 6
               Left = 271
               Bottom = 125
               Right = 468
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FLATS"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 245
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 4
         End
         Begin Table = "OCCUPATION_TYPES"
            Begin Extent = 
               Top = 246
               Left = 38
               Bottom = 365
               Right = 245
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DOG_SUP"
            Begin Extent = 
               Top = 15
               Left = 526
               Bottom = 231
               Right = 695
            End
            DisplayFlags = 280
            TopColumn = 6
         End
         Begin Table = "View_BUILDINGS"
            Begin Extent = 
               Top = 246
               Left = 283
               Bottom = 365
               Right = 452
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
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Widt', 'SCHEMA', 'dbo', 'VIEW', 'view_cessia'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'h = 1500
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_cessia'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_cessia'
go

