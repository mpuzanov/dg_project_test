-- dbo.view_counter_all source

CREATE   VIEW [dbo].[view_counter_all]
AS
SELECT
	cl.fin_id
	,ot.start_date
	,cl.counter_id
	,cl.occ
	,cl.service_id
	,cl.occ_counter
	,cl.internal
	,cl.no_vozvrat
	,cl.KolmesForPeriodCheck
	,cl.kol_occ
	,o.tip_id
	,o.address
	,o.PROPTYPE_ID
	,ot.name AS tip_name
	,c.flat_id
	,c.build_id AS bldn_id
	,c.serial_number
	,c.unit_id
	,c.date_create
	,c.date_del
	,c.date_edit
	,c.PeriodCheck
	,c.PeriodLastCheck
	,c.PeriodInterval		
	,c.id_pu_gis
	,c.mode_id
	,ot.payms_value
FROM dbo.Counter_list_all AS cl
JOIN dbo.Counters AS c 
	ON cl.counter_id = c.id
JOIN dbo.Occupations AS o 
	ON cl.occ = o.occ
JOIN dbo.VOcc_types_all_access AS ot 
	ON o.tip_id = ot.id
	AND cl.fin_id = ot.fin_id;
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
         Configuration = "(H (2[55] 3) )"
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
         Configuration = "(V (2) )"
      End
      ActivePaneConfig = 5
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "cl"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 125
               Right = 442
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ot"
            Begin Extent = 
               Top = 6
               Left = 480
               Bottom = 125
               Right = 666
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 704
               Bottom = 125
               Right = 873
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
         Width = 840
         Width = 2250
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      PaneHidden = 
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
         Or = 13', 'SCHEMA', 'dbo', 'VIEW', 'view_counter_all'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'50
      End
   End
End
', 'SCHEMA', 'dbo', 'VIEW', 'view_counter_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_counter_all'
go

