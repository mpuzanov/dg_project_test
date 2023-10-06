-- dbo.view_sup_occ_all source

CREATE   view [dbo].[view_sup_occ_all]
as
select
	sa.name as sup_name
	,os.fin_id
	,os.occ
	,os.occ_sup
	,os.sup_id
	,os.saldo
	,os.value
	,os.added
	,os.paid
	,os.paymaccount
	,os.paymaccount_peny
	,os.paymaccount - os.paymaccount_peny as paymaccount_serv
	,os.debt
	,os.penalty_calc
	,os.penalty_value
	,os.penalty_old_new
	,os.penalty_old
	,os.whole_payment
	,os.kolmesdolg
	,os.penalty_old_edit
	,os.paid_old
	,os.dog_int
	,os.id_jku_gis
	,os.cessia_dolg_mes_old
	,os.cessia_dolg_mes_new
	,o.address
	,o.tip_id
	,b.street_name
	,b.nom_dom
	,ds.dog_name
	,ds.dog_id
	,f.nom_kvr
	,f.bldn_id
from dbo.vocc_suppliers as os 
inner join dbo.suppliers_all as sa
	on os.sup_id = sa.id
inner join dbo.occupations as o
	on os.occ = o.occ
inner join dbo.flats f
	on o.flat_id = f.id
inner join dbo.view_buildings as b
	on f.bldn_id = b.id
left outer join dbo.dog_sup ds
	on os.sup_id = ds.sup_id
	and os.dog_int = ds.id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[55] 4[7] 2[21] 3) )"
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
         Top = -214
         Left = 0
      End
      Begin Tables = 
         Begin Table = "OCC_SUPPLIERS"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 233
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SUPPLIERS_ALL"
            Begin Extent = 
               Top = 6
               Left = 271
               Bottom = 125
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OCCUPATIONS"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 245
               Right = 235
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "View_BUILDINGS"
            Begin Extent = 
               Top = 277
               Left = 35
               Bottom = 444
               Right = 204
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DOG_SUP"
            Begin Extent = 
               Top = 127
               Left = 749
               Bottom = 290
               Right = 918
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FLATS"
            Begin Extent = 
               Top = 241
               Left = 333
               Bottom = 373
               Right = 502
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
         Column ', 'SCHEMA', 'dbo', 'VIEW', 'view_sup_occ_all'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'= 1755
         Alias = 900
         Table = 1740
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_sup_occ_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_sup_occ_all'
go

