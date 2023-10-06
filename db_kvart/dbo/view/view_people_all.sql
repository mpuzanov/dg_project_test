-- dbo.view_people_all source

CREATE   VIEW [dbo].[view_people_all]
AS
	SELECT b.fin_current AS fin_id
		 , p.Occ
		 , p.ID AS owner_id
		 , p.people_uid
		 , p.birthdate
		 , p.status2_id
		 , p.status_id
		 , p.lgota_id
		 , p.sex
		 , p.last_name
		 , p.first_name
		 , p.second_name
		 , p.ID
		 , p.lgota_kod
		 , p.Fam_id
		 , p.Dola_priv1
		 , p.Dola_priv2
		 , p.is_owner_flat
	FROM dbo.People AS p 
		JOIN dbo.Occupations AS o 
			ON p.Occ = o.Occ
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings as b 
			ON f.bldn_id=b.id
	WHERE p.Del = 0
	UNION /* UNION ALL - нельзя */
	SELECT ph.fin_id
		 , ph.Occ
		 , ph.owner_id
		 , p.people_uid
		 , p.birthdate
		 , ph.status2_id
		 , ph.status_id
		 , ph.lgota_id
		 , p.sex
		 , p.last_name
		 , p.first_name
		 , p.second_name
		 , ph.owner_id
		 , p.lgota_kod
		 , p.Fam_id
		 , p.Dola_priv1
		 , p.Dola_priv2
		 , p.is_owner_flat
	FROM dbo.People_history AS ph 
		LEFT JOIN dbo.People AS p 
			ON ph.owner_id = p.ID;
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
         Configuration = "(H (4[30] 2[40] 3) )"
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
      ActivePaneConfig = 3
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_people_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_people_all'
go

