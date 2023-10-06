-- dbo.vocc source

CREATE   VIEW [dbo].[vocc]
AS
SELECT
	o.occ
   ,o.jeu
   ,o.schtl
   ,o.flat_id
   ,o.tip_id
   ,o.roomtype_id
   ,o.proptype_id
   ,o.status_id
   ,o.living_sq
   ,o.total_sq
   ,o.teplo_sq
   ,o.norma_sq
   ,o.socnaim
   ,o.saldo
   ,o.saldo_serv
   ,o.saldo_edit
   ,o.value
   ,o.discount
   ,o.compens
   ,o.added
   ,o.added_ext
   ,o.paymaccount
   ,o.paymaccount_peny
   ,o.paid
   ,o.paid_minus
   ,o.paid_old
   ,o.debt
   ,o.penalty_calc
   ,o.penalty_value
   ,o.penalty_added
   ,o.penalty_old_new
   ,o.penalty_old
   ,o.penalty_old_edit
   ,o.address
   ,o.data_rascheta
   ,o.comments
   ,o.comments2
   ,o.rooms
   ,o.kol_people
   ,o.kol_people_reg
   ,o.kol_people_all
   ,o.id_jku_gis
   ,o.id_els_gis
   ,b.fin_current as fin_id
   ,ot.name as tip_name
   ,o.saldoall
   ,o.paymaccount_servall
   ,o.paidall
   ,o.addedall
   ,o.prefix
   ,o.kolmesdolg
   ,o.room_id
   ,ot.payms_value
   ,f.bldn_id
   ,f.bldn_id as build_id
   ,f.nom_kvr
   ,f.nom_kvr_sort
   ,f.floor
   ,f.id_nom_gis
   ,f.is_flat
   ,f.is_unpopulated
   ,o.schtl_old
   ,o.telephon

	,(o.paymaccount-o.paymaccount_peny) AS paymaccount_serv
	, CASE 
		WHEN ((((o.saldo+o.paid)+o.Paid_minus)-(o.paymaccount-o.PaymAccount_peny))+((o.penalty_value+o.penalty_added)+o.penalty_old_new))<0 
		THEN 0 
		ELSE (((o.saldo+o.paid)+o.Paid_minus)-(o.paymaccount-o.PaymAccount_peny))+((o.penalty_value+o.penalty_added)+o.penalty_old_new) 
	 END
	AS whole_payment
	,((o.penalty_old_new+o.penalty_added)+o.penalty_value) AS debt_peny

FROM dbo.Occupations AS o
INNER JOIN dbo.VOcc_types AS ot	ON 
	o.tip_id = ot.id
INNER JOIN dbo.Flats AS f ON 
	o.flat_id = f.id
INNER JOIN dbo.Buildings AS b ON 
	f.bldn_id = b.id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (140 420 220 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 50 4 25 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 50 2 25 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 30 2 40 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 56 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 66 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 50 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (156 418 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 75 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (166 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 60 2))"
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
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 181
               Right = 247
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ot"
            Begin Extent = 
               Top = 51
               Left = 293
               Bottom = 182
               Right = 494
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FLATS"
            Begin Extent = 
               Top = 0
               Left = 591
               Bottom = 181
               Right = 760
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
', 'SCHEMA', 'dbo', 'VIEW', 'vocc'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'vocc'
go

