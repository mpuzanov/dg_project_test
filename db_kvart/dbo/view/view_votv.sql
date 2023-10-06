-- dbo.view_votv source

CREATE   VIEW [dbo].[view_votv]
AS
	WITH cte AS
	(
		SELECT 'хвод' AS serv1
			 , 'вотв' AS serv2
			 , 'Водоотведение ХВС' AS service_name
		UNION ALL
		SELECT 'гвод' AS serv1
			 , 'вотв' AS serv2
			 , 'Водоотведение ГВС' AS service_name
		UNION ALL
		SELECT 'хвс2' AS serv1
			 , 'вот2' AS serv2
			 , 'Водоотведение ХВС' AS service_name
		UNION ALL
		SELECT 'гвс2' AS serv1
			 , 'вот2' AS serv2
			 , 'Водоотведение ГВС' AS service_name
	)
	SELECT cp.start_date AS start_date
		 , t1.fin_id
		 , t1.Occ
		 , t1.service_id
		 , cte.service_name
		 , t2.tarif
		 , t1.kol
		 , CAST(t2.tarif * t1.kol AS DECIMAL(9, 2)) AS Value
		 , t1.is_counter
		 , t1.metod
		 , dbo.Fun_GetMetodText(t1.metod) AS metod_name
		 , t1.metod_old
		 , t1.unit_id
		 , t1.kol_norma
		 , t1.sup_id
		 , t1.build_id
		 , t1.kol_norma_single
		 , t1.source_id
		 , t1.mode_id
		 , t1.occ_sup_paym
		 , t1.date_start
		 , t1.date_end
		 , t1.kol_added
		 , t1.koef_day
	FROM dbo.Paym_history AS t1
		JOIN cte ON 
			t1.service_id = cte.serv1
		JOIN dbo.Paym_history AS t2 ON 
			t1.fin_id = t2.fin_id
			AND t1.Occ = t2.Occ
			AND t1.sup_id = t2.sup_id
			AND t2.service_id = cte.serv2
		LEFT JOIN dbo.Calendar_period cp ON 
			cp.fin_id = t1.fin_id
	WHERE (t1.service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2'));
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
         Begin Table = "View_paym"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 233
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_votv'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_votv'
go

