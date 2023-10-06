-- dbo.vocc_types_all_lite source

CREATE   view [dbo].[vocc_types_all_lite]
as
	select o.fin_id
		 , o.start_date
		 , o.id
		 , o.name
		 , o.payms_value
		 , o.id_accounts
		 , o.id_barcode
		 , o.bank_account
		 , o.penalty_calc_tip
		 , o.penalty_metod
		 , o.lastpaymday
		 , o.fincloseddata
		 , o.paymcloseddata
		 , dbo.fun_namefinperioddate(o.start_date) as strmes
		 , o.is_counter_cur_tarif
		 , o.account_rich
	from (
		select fin_id
			 , start_date
			 , id
			 , name
			 , payms_value
			 , id_accounts
			 , id_barcode
			 , bank_account
			 , penalty_calc_tip
			 , penalty_metod
			 , lastpaymday
			 , fincloseddata
			 , paymcloseddata
			 , is_counter_cur_tarif
			 , o2.account_rich
		from dbo.occupation_types_history as o2
		union
		select fin_id
			 , start_date
			 , id
			 , name
			 , payms_value
			 , id_accounts
			 , id_barcode
			 , bank_account
			 , penalty_calc_tip
			 , penalty_metod
			 , lastpaymday
			 , fincloseddata
			 , paymcloseddata
			 , is_counter_cur_tarif
			 , o1.account_rich
		from dbo.occupation_types as o1
	) as o;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[50] 4[14] 2[27] 3) )"
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
         Begin Table = "GLOBAL_VALUES"
            Begin Extent = 
               Top = 6
               Left = 290
               Bottom = 136
               Right = 487
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 224
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
', 'SCHEMA', 'dbo', 'VIEW', 'vocc_types_all_lite'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'vocc_types_all_lite'
go

