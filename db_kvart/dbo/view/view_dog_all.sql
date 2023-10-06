-- dbo.view_dog_all source

CREATE   VIEW [dbo].[view_dog_all]
AS
SELECT
	ds.dog_id
	,db.fin_id
	,db.build_id
	,ds.sup_id
	,ds.tip_id
	,ds.dog_name
	,sup.service_id
	,s.name AS serv_name
	,sa.name AS sup_name
	,sup.id AS source_id
	,gb.start_date
	,gb.StrMes AS fin_name
	,ds.id
	,ds.first_occ
	,ds.bank_account
	,ds.dog_date
	,ds.id_accounts
	,ds.date_edit
	,ds.login_edit
	,sa.account_one
FROM dbo.DOG_BUILD AS db
INNER JOIN dbo.DOG_SUP AS ds
	ON db.dog_int = ds.id
INNER JOIN dbo.SUPPLIERS AS sup
	ON ds.sup_id = sup.sup_id
INNER JOIN dbo.SERVICES AS s
	ON sup.service_id = s.id
INNER JOIN dbo.SUPPLIERS_ALL AS sa
	ON ds.sup_id = sa.id
	AND sup.sup_id = sa.id
INNER JOIN dbo.GLOBAL_VALUES AS gb
	ON db.fin_id = gb.fin_id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[50] 4[11] 2[20] 3) )"
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
         Begin Table = "db"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 142
               Right = 219
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ds"
            Begin Extent = 
               Top = 23
               Left = 322
               Bottom = 329
               Right = 503
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sup"
            Begin Extent = 
               Top = 0
               Left = 522
               Bottom = 135
               Right = 703
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 707
               Bottom = 130
               Right = 888
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa"
            Begin Extent = 
               Top = 158
               Left = 31
               Bottom = 282
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 7
         End
         Begin Table = "gb"
            Begin Extent = 
               Top = 132
               Left = 707
               Bottom = 269
               Right = 909
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
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width', 'SCHEMA', 'dbo', 'VIEW', 'view_dog_all'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N' = 1500
         Width = 1500
         Width = 2490
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_dog_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_dog_all'
go

