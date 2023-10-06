/* volap_fact*/
CREATE   view [dbo].[volap_fact]
as
	select ph.fin_id
		 , cp.start_date
		 , vb.bldn_id
		 , vb.sector_id
		 , vb.tip_id
		 , oh.roomtype_id
		 , oh.proptype_id
		 , oh.living_sq
		 , oh.total_sq
		 , ph.occ
		 , f.nom_kvr
		 , ph.service_id
		 , ph.tarif
		 , case
			   when (oh.saldo - oh.paymaccount)
				   > 0 then ph.saldo - ph.paymaccount
			   else 0
		   end as 'saldopaym0'
		 , ph.saldo
		 , ph.saldo + ph.penalty_prev as saldowithpeny
		 , ph.value
		 , ph.discount
		 , (ph.added - coalesce(t_sub.value,0))  as added
		 , ph.compens
		 , ph.paid
		 , ph.paid + ph.penalty_serv  as paidwithpeny
		 , ph.paymaccount
		 , ph.paymaccount_peny
		 , ph.paymaccount - ph.paymaccount_peny as paymaccount_serv
		 , ph.debt
		 , ph.debt + ph.penalty_old + ph.penalty_serv  as debtwithpeny
		 , ph.source_id
		 , ph.mode_id
		 , ph.saldo - (ph.paymaccount - ph.paymaccount_peny) as saldo_paymaccount
		 , oh.status_id
		 , ph.is_counter
		 , ph.kol
		 , (coalesce(ph.kol_added,0) - coalesce(t_sub.kol,0)) as kol_added
		 , ph.account_one
		 , ph.metod
		 , ph.sup_id
		 , case when(ph.sup_id > 0) then ph.occ_sup_paym else 0 end as occ_serv --cl.occ_serv
		 , case
			   when (coalesce(ph.metod, 1) not in (3,
				   4)) and
				   (s.is_build = 0) then ph.kol
			   else 0
		   end as kol_norma
		 , case
			   when ph.metod = 3 then ph.kol
			   else 0
		   end as kol_ipu
		 , case
			   when (ph.metod = 4) or
				   (s.is_build = 1) then ph.kol
			   else 0
		   end as kol_opu
		 , vb.build_type
		 , ph.penalty_old + ph.paymaccount_peny as 'penalty_old'
		 , ph.penalty_serv as 'penalty_serv'
		 , ph.penalty_old + ph.penalty_serv as 'penalty_itog'
		 , vb.dog_bit
		 , f.nom_kvr_sort
		 , coalesce(t_sub.value,0) as sub_value
		 , coalesce(t_sub.kol,0) as sub_kol
	from dbo.paym_history as ph
		inner join dbo.calendar_period as cp 
			on ph.fin_id = cp.fin_id
		inner join dbo.services as s 
			on ph.service_id = s.id
		inner join dbo.occ_history as oh 
			on oh.occ = ph.occ
			and ph.fin_id = oh.fin_id
		inner join dbo.flats as f 
			on oh.flat_id = f.id
		inner join dbo.buildings_history as vb 
			on f.bldn_id = vb.bldn_id
			and oh.fin_id = vb.fin_id
		cross apply (
			select sum(va.value) as value
				,sum(va.kol) as kol
			from dbo.added_payments_history va
			where va.fin_id = ph.fin_id
				and va.occ = ph.occ
				and va.service_id = ph.service_id
				and va.sup_id = ph.sup_id
				and va.add_type = 15
		) as t_sub
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
         Begin Table = "ph"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 231
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 269
               Bottom = 136
               Right = 443
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "oh"
            Begin Extent = 
               Top = 6
               Left = 481
               Bottom = 136
               Right = 684
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f"
            Begin Extent = 
               Top = 6
               Left = 722
               Bottom = 136
               Right = 896
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "vb"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 228
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cl"
            Begin Extent = 
               Top = 138
               Left = 266
               Bottom = 268
               Right = 440
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
     ', 'SCHEMA', 'dbo', 'VIEW', 'volap_fact'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'    Output = 720
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
', 'SCHEMA', 'dbo', 'VIEW', 'volap_fact'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'volap_fact'
go

