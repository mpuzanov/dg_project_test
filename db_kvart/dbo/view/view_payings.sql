-- dbo.view_payings source

CREATE   VIEW [dbo].[view_payings]  AS 
SELECT
	p.id
	,p.pack_id
	,p.occ
	,p.service_id
	,p.value
	,pd.fin_id
	,pd.day
	,pd.forwarded
	,pd.date_edit
	,b.short_name AS source_name
	,p2.Name AS tip_paym
	,cp.StrFinPeriod AS fin_name
	,p.paymaccount_peny
	,p.sup_id
	,pd.tip_id
	,p2.id AS tip_paym_id
	,b.id AS bank_id
	,p2.peny_no
	,po.ext
	,po.description
	,p.dog_int
	,p.commission
	,p.occ_sup
	,p.paying_vozvrat
	,p.scan
	,pd.checked
	,p.peny_save
	,P.paying_manual
	,p.paying_uid
	,p.filedbf_id
	,pd.pack_uid
	,P.comment
FROM dbo.Payings AS p 
INNER JOIN dbo.Paydoc_packs AS pd 
	ON p.pack_id = pd.id
INNER JOIN dbo.Paycoll_orgs AS po 
	ON pd.source_id = po.id
INNER JOIN dbo.Bank AS b 
	ON po.BANK = b.id
INNER JOIN dbo.Paying_types AS p2 
	ON po.vid_paym = p2.id
INNER JOIN dbo.Calendar_period cp
	ON cp.fin_id = pd.fin_id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[17] 2[29] 3) )"
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
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 240
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 4
         End
         Begin Table = "pd"
            Begin Extent = 
               Top = 6
               Left = 259
               Bottom = 253
               Right = 428
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 466
               Bottom = 236
               Right = 635
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 6
               Left = 673
               Bottom = 218
               Right = 842
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "p2"
            Begin Extent = 
               Top = 6
               Left = 880
               Bottom = 121
               Right = 1049
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
         Alias = 1740
         Table = 1170
         Output', 'SCHEMA', 'dbo', 'VIEW', 'view_payings'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N' = 720
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_payings'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_payings'
go

