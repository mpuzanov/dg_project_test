-- dbo.view_added source

-- dbo.view_added source

CREATE   VIEW [dbo].[view_added]
AS
	SELECT cp.start_date AS start_date
		 , t1.*
	FROM (
		SELECT t.fin_id
			 , Occ
			 , service_id
			 , add_type
			 , Value
			 , add_type2
			 , doc
			 , data1
			 , data2
			 , Hours
			 , Vin1
			 , Vin2
			 , doc_no
			 , doc_date
			 , tnorm2
			 , kol
			 , dsc_owner_id
			 , user_edit
			 , manual_bit
			 , fin_id_paym
			 , comments
			 , id AS kod
			 , date_edit
			 , t.id AS id
			 , repeat_for_fin
			 , t.sup_id
		FROM dbo.Added_Payments AS t
		UNION
		SELECT t.fin_id
			 , t.Occ
			 , t.service_id
			 , t.add_type
			 , t.Value
			 , t.add_type2
			 , t.doc
			 , t.data1
			 , t.data2
			 , t.Hours
			 , t.Vin1
			 , t.Vin2
			 , t.doc_no
			 , t.doc_date
			 , t.tnorm2
			 , t.kol
			 , t.dsc_owner_id
			 , t.user_edit
			 , t.manual_bit
			 , t.fin_id_paym
			 , t.comments
			 , NULL AS kod
			 , t.date_edit AS date_edit
			 , t.id AS id
			 , repeat_for_fin
			 , t.sup_id
		FROM dbo.Added_Payments_History AS t
	) AS t1
		LEFT JOIN dbo.Calendar_period cp ON cp.fin_id = t1.fin_id
		JOIN dbo.Occupations o ON o.Occ = t1.Occ
		JOIN dbo.VOcc_types_access AS ot ON ot.id = o.tip_id -- для ограничения доступа по типу фонда;
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_added'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_added'
go

