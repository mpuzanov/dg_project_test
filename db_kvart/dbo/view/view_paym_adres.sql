-- dbo.view_paym_adres source

CREATE   VIEW [dbo].[view_paym_adres]  AS 
SELECT
	p.fin_id,
	p.start_date,
	p.occ,
	p.service_id,
	p.tarif,
	p.saldo,
	p.Value,
	p.Added,
	p.Paid,
	p.PaymAccount,
	p.PaymAccount_peny,
	p.Paymaccount_serv,
	p.Debt,
	p.kol,
	p.account_one,
	p.is_counter,
	p.metod,
	p.unit_id,
	p.kol_norma,
	p.sup_id,
	p.is_build,
	p.penalty_prev,
	p.Penalty_old,
	p.penalty_serv,
	p.serv_name AS serv_name,
	o.tip_name,
	d.Name AS div_name,
	sec.Name AS sector_name,
	s.full_Name AS street_name,
	b.nom_dom,
	b.nom_dom_sort,
	o.flat_id,
	o.nom_kvr,
	o.nom_kvr_sort,
	o.bldn_id,
	b.tip_id
FROM dbo.View_paym AS p
INNER JOIN dbo.VOcc AS o
	ON p.occ = o.occ
INNER JOIN dbo.Buildings AS b
	ON o.bldn_id = b.id
INNER JOIN dbo.Streets AS s 
	ON b.street_id = s.id
LEFT OUTER JOIN dbo.Divisions AS d 
	ON b.div_id = d.id
LEFT OUTER JOIN dbo.Sector AS sec 
	ON b.sector_id = sec.id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[19] 4[33] 2[20] 3) )"
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
         Begin Table = "View_PAYM"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 195
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "View_BUILDINGS"
            Begin Extent = 
               Top = 11
               Left = 784
               Bottom = 190
               Right = 953
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SERVICES"
            Begin Extent = 
               Top = 0
               Left = 280
               Bottom = 119
               Right = 449
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "VOCC"
            Begin Extent = 
               Top = 6
               Left = 487
               Bottom = 188
               Right = 679
            End
            DisplayFlags = 280
            TopColumn = 41
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 27
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
         Width = 1500
         Width = 1500
         Width = 1', 'SCHEMA', 'dbo', 'VIEW', 'view_paym_adres'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'500
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_paym_adres'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_paym_adres'
go

