-- dbo.vocc_types source

CREATE   VIEW [dbo].[vocc_types]
AS
	SELECT o.id
		 , o.name
		 , o.payms_value
		 , o.id_accounts
		 , o.adres
		 , o.fio
		 , o.telefon
		 , o.id_barcode
		 , o.bank_account
		 , o.laststr1
		 , o.penalty_calc_tip
		 , o.counter_metod
		 , o.counter_votv_ras
		 , o.laststr2
		 , o.penalty_metod
		 , o.occ_min
		 , o.occ_max
		 , o.occ_prefix_tip
		 , o.paym_order
		 , o.paym_order_metod
		 , o.lastpaym
		 , o.namesoderhousing
		 , o.fin_id
		 , o.start_date
		 , o.LastPaymDay
		 , o.fincloseddata
		 , o.PaymClosed
		 , o.PaymClosedData
		 , o.state_id
		 , o.logo
		 , CAST(CONCAT(DATENAME(MONTH, o.start_date), ' ', DATENAME(YEAR, o.start_date)) AS VARCHAR(15)) AS StrMes
		 , o.SaldoEditTrue
		 , o.email
		 , o.paymaccount_minus
		 , o.saldo_rascidka
		 , o.counter_add_ras_norma
		 , o.synonym_name
		 , o.inn
		 , o.people0_counter_norma
		 , o.PaymRaskidkaAlways
		 , o.ogrn
		 , o.comments
		 , o.tip_org_for_account
		 , o.tip_paym_blocked
		 , o.tip_details
		 , o.counter_votv_norma
		 , o.ras_paym_fin_new
		 , o.people_reg_blocked
		 , o.kpp
		 , o.is_PrintFioPrivat
		 , o.is_ValueBuildMinus
		 , o.is_2D_Code
		 , o.raschet_no
		 , o.raschet_agri
		 , o.is_counter_cur_tarif
		 , o.is_paying_saldo_no_paid
		 , o.is_not_allocate_economy
		 , uo.only_read
		 , o.telefon_pasp
		 , uo.fin_id_start AS fin_id_start
		 , o.barcode_charset
		 , o.ras_no_counter_poverka
		 , o.only_pasport
		 , o.only_value
		 , o.account_rich
		 , o.is_counter_add_balance
		 , o.web_site
		 , o.adres_fact
		 , o.rezhim_work
		 , o.email_subscribe
		 , o.PenyBeginDolg
		 , o.tip_occ
		 , o.blocked_counter_add_ras_norma
		 , o.export_gis
		 , o.export_gis_occ_prefix
		 , o.bank_format_out
		 , o.bank_file_out
		 , o.watermark_text
		 , o.watermark_dolg_mes
		 , o.is_only_quarter
		 , o.is_calc_subs12
		 , o.is_cash_serv
		 , o.peny_paym_blocked
		 , o.soi_metod_calc
		 , o.soi_isTotalSq_Pasport
		 , o.odn_big_norma
		 , o.soi_votv_fact
		 , o.ppu_value_allow_negativ
		 , o.is_peny_blocked_total_sq_empty
		 , o.is_peny_current_stavka_cb
		 , o.count_month_avg_counter
		 , o.tip_uid
		 , o.is_peny_serv
		 , o.peny_service_id
		 , o.decimal_round
	     , o.commission_bank_code
		 , o.soi_is_transfer_economy
		 , o.is_vozvrat_votv_sum
		 , o.soi_boiler_only_hvs
		 , o.is_export_gis_without_paid
		 , o.set_start_day_period_dolg
		 , o.is_recom_for_payment
		 , o.last_paym_day_count_payments
		 , o.is_epd_saldo
		 , o.count_min_month_for_avg_counter
	FROM dbo.Occupation_Types AS o
		INNER JOIN (
			SELECT su.SYSUSER
				 , uot.ONLY_TIP_ID
				 , CAST(uot.only_read AS BIT) AS only_read
				 , uot.fin_id_start
			FROM (SELECT system_user AS SYSUSER) AS su
				LEFT OUTER JOIN dbo.Users_occ_types AS uot ON 
					su.SYSUSER = uot.SYSUSER
		) AS uo ON (o.id = uo.ONLY_TIP_ID OR uo.ONLY_TIP_ID IS NULL);
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[37] 4[17] 2[21] 3) )"
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
         Top = -534
         Left = 0
      End
      Begin Tables = 
         Begin Table = "o"
            Begin Extent = 
               Top = 18
               Left = 52
               Bottom = 671
               Right = 262
            End
            DisplayFlags = 280
            TopColumn = 25
         End
         Begin Table = "uo"
            Begin Extent = 
               Top = 21
               Left = 300
               Bottom = 140
               Right = 469
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GLOBAL_VALUES"
            Begin Extent = 
               Top = 227
               Left = 324
               Bottom = 393
               Right = 512
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
      Begin ColumnWidths = 57
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
         ', 'SCHEMA', 'dbo', 'VIEW', 'vocc_types'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'Width = 1500
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
         Column = 2370
         Alias = 1770
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
', 'SCHEMA', 'dbo', 'VIEW', 'vocc_types'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'vocc_types'
go

