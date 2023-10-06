-- dbo.view_paym source

CREATE   VIEW [dbo].[view_paym]
AS

	SELECT cp.start_date AS start_date
		 , t1.fin_id
		 , t1.Occ
		 , t1.service_id
		 , s.name as serv_name		 
		 , t1.tarif
		 , t1.SALDO
		 , t1.Value
		 , t1.Discount
		 , t1.Added
		 , t1.Compens
		 , t1.Paid
		 , t1.PaymAccount
		 , t1.PaymAccount_peny
		 , t1.Paymaccount_Serv
		 , t1.Debt
		 , t1.kol
		 , t1.account_one
		 , t1.subsid_only
		 , t1.is_counter
		 , t1.metod
		 --, dbo.Fun_GetMetodText(t1.metod) AS metod_name
		 , cm1.name AS metod_name
		 , t1.metod_old
		 --, dbo.Fun_GetMetodText(t1.metod_old) AS metod_old_name
		 , cm2.name AS metod_old_name
		 , t1.unit_id
		 , t1.kol_norma
		 , t1.sup_id
		 , t1.build_id
		 , t1.penalty_prev
		 , t1.Penalty_old
		 , t1.penalty_serv
		 , t1.kol_norma_single
		 , t1.source_id
		 , t1.mode_id
		 , t1.occ_sup_paym
		 , t1.Koef
		 , COALESCE(t1.date_start, cp.start_date) AS date_start
		 , COALESCE(t1.date_end, cp.end_date) AS date_end
		 , t1.kol_added
		 , s.is_build
		 , s.is_peny
		 , CASE s.id
			   WHEN 'хвс2' THEN 'хвод'
			   WHEN 'гвс2' THEN 'гвод'
			   WHEN 'ото2' THEN 'отоп'
			   WHEN 'эле2' THEN 'элек'
			   --WHEN '' THEN ''
			   ELSE s.id
		   END AS serv_counter
		 , cp.KolDayFinPeriod
		 , COALESCE(t1.koef_day,1) AS koef_day
		 , CASE 
				WHEN COALESCE(t1.date_start, cp.start_date)>COALESCE(t1.date_end, cp.end_date) THEN 0
				WHEN (DATEDIFF(DAY, COALESCE(t1.date_start, cp.start_date), COALESCE(t1.date_end, cp.end_date)) + 1)>cp.KolDayFinPeriod THEN cp.KolDayFinPeriod
				ELSE (DATEDIFF(DAY, COALESCE(t1.date_start, cp.start_date), COALESCE(t1.date_end, cp.end_date)) + 1) 
		END AS kol_day
	FROM (
		SELECT p.fin_id
			 , p.Occ
			 , p.service_id
			 , p.subsid_only
			 , p.tarif
			 , p.SALDO
			 , p.Value
			 , 0 AS discount
			 , p.Added
			 , 0 AS Compens
			 , p.Paid
			 , p.PaymAccount
			 , p.PaymAccount_peny
			 , (p.PaymAccount - p.PaymAccount_peny) AS paymaccount_serv
			 , p.Debt
			 , p.kol
			 , p.account_one
			 , p.is_counter
			 , p.metod			 
			 , p.metod_old			 
			 , p.unit_id
			 , p.kol_norma
			 , p.sup_id
			 , p.build_id
			 , P.penalty_prev
			 , p.Penalty_old
			 , p.penalty_serv
			 , p.kol_norma_single
			 , p.source_id
			 , p.mode_id
			 , p.occ_sup_paym
			 , p.Koef
			 , p.date_start
			 , p.date_end
			 , p.kol_added
			 , P.koef_day
		FROM dbo.Paym_list AS p

		UNION

		SELECT ph.fin_id
			 , ph.Occ
			 , ph.service_id
			 , ph.subsid_only
			 , ph.tarif
			 , ph.SALDO
			 , ph.Value
			 , ph.Discount
			 , ph.Added
			 , ph.Compens
			 , ph.Paid
			 , ph.PaymAccount
			 , ph.PaymAccount_peny
			 , (ph.PaymAccount - ph.PaymAccount_peny) AS paymaccount_serv
			 , ph.Debt
			 , ph.kol
			 , ph.account_one
			 , ph.is_counter
			 , ph.metod
			 , ph.metod_old
			 , ph.unit_id
			 , ph.kol_norma
			 , ph.sup_id
			 , ph.build_id
			 , ph.penalty_prev
			 , ph.Penalty_old
			 , ph.penalty_serv
			 , ph.kol_norma_single
			 , ph.source_id
			 , ph.mode_id
			 , ph.occ_sup_paym
			 , ph.Koef
			 , ph.date_start
			 , ph.date_end
			 , ph.kol_added
			 , ph.koef_day
		FROM dbo.Paym_history AS ph
	) AS t1
		JOIN dbo.Services AS s ON t1.service_id = s.id
		LEFT JOIN dbo.Calendar_period cp ON cp.fin_id = t1.fin_id
		LEFT JOIN dbo.view_metod cm1 ON t1.metod=cm1.id
		LEFT JOIN dbo.view_metod cm2 ON t1.metod_old=cm2.id;
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
         Configuration = "(H (2[66] 3) )"
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
         Or = 1350
      End
   End
End
', 'SCHEMA', 'dbo', 'VIEW', 'view_paym'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_paym'
go

