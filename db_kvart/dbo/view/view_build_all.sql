-- dbo.view_build_all source

CREATE   VIEW [dbo].[view_build_all]
AS
	SELECT t1.*
		 , s.full_name AS street_name
		 , d.name AS div_name
		 , sec.name AS sector_name
		 , CONCAT(s.name , ' д.' , t1.nom_dom) AS adres
		 , Tw.name AS town_name
		 , ot.start_date
		 , ot.name AS tip_name
	FROM (
		SELECT t.fin_id
			 , t.bldn_id
			 , b.Id AS build_id
			 , t.street_id
			 , t.sector_id
			 , t.div_id
			 , t.tip_id
			 , t.nom_dom
			 , t.dog_bit
			 , t.old
			 , b.town_id
			 , t.arenda_sq
			 , t.build_total_sq
			 , t.build_total_area
			 , t.opu_sq
			 , t.opu_sq_elek
			 , t.opu_sq_otop
			 , t.norma_gkal
			 , t.build_type
			 , t.norma_gkal_gvs
			 , t.is_paym_build
			 , t.norma_gaz_gvs
			 , b.nom_dom_sort
			 , b.build_uid
			 , t.account_rich
		     , b.is_value_build_minus
		     , b.is_not_allocate_economy
			 , b.soi_is_transfer_economy
		FROM dbo.Buildings_history AS t 
			JOIN dbo.Buildings AS b ON t.bldn_id = b.Id
		UNION
		SELECT t.fin_current AS fin_id
			 , t.Id
			 , t.Id AS build_id
			 , t.street_id
			 , t.sector_id
			 , t.div_id
			 , t.tip_id
			 , t.nom_dom
			 , t.dog_bit
			 , t.old
			 , t.town_id
			 , t.arenda_sq
			 , t.build_total_sq
			 , t.build_total_area
			 , t.opu_sq
			 , t.opu_sq_elek
			 , t.opu_sq_otop
			 , t.norma_gkal
			 , t.build_type
			 , t.norma_gkal_gvs
			 , t.is_paym_build
			 , t.norma_gaz_gvs
			 , t.nom_dom_sort
			 , t.build_uid
			 , t.account_rich
		     , t.is_value_build_minus
		     , t.is_not_allocate_economy
			 , t.soi_is_transfer_economy
		FROM dbo.Buildings AS t 
	) AS t1
		INNER JOIN dbo.VOcc_types_all_access AS ot 
			ON t1.tip_id = ot.Id
				AND t1.fin_id = ot.fin_id
		INNER JOIN dbo.Streets AS s 
			ON t1.street_id = s.Id
		INNER JOIN dbo.Divisions AS d 
			ON t1.div_id = d.Id
		JOIN dbo.Towns AS Tw 
			ON t1.town_id = Tw.Id
		LEFT JOIN dbo.Sector AS sec 
			ON t1.sector_id = sec.Id;
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
         Configuration = "(H (1[50] 2[25] 3) )"
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_build_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_build_all'
go

