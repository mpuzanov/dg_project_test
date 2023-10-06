-- dbo.view_services source

CREATE   VIEW [dbo].[view_services]
AS
SELECT
	s.id
	,s.name
	,s.short_name
	,s.service_no
	,s.service_type
	,s.is_koef
	,s.is_subsid
	,s.is_norma
	,s.num_colon
	,s.is_counter
	,s.service_kod
	,s.var_subsid_only
	,s.sort_no
	,s.is_paym
	,s.is_peny
	,s.serv_from
	,s.is_build
	,s.is_build_serv
	,s.sort_paym
	,s.serv_vid
	,s.is_koef_up
	,s.no_export_volume_gis
	,s.unit_id_default
	,s.date_edit
FROM dbo.SERVICES AS s
INNER JOIN (SELECT
		su.SYSUSER
		,us.ONLY_SERVICE_ID
	FROM (SELECT
			SUSER_SNAME() AS SYSUSER) AS su
	LEFT OUTER JOIN (SELECT
			p1.sysuser
			,p2.ONLY_SERVICE_ID
		FROM dbo.Group_members AS p1
		INNER JOIN dbo.Group_services AS p2
			ON p1.group_id = p2.group_id) AS us
		ON su.SYSUSER = us.sysuser) AS uo
	ON s.id = COALESCE(uo.ONLY_SERVICE_ID, s.id);
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
         Configuration = "(H (1[28] 2[40] 3) )"
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
      ActivePaneConfig = 2
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 130
               Right = 219
            End
            DisplayFlags = 280
            TopColumn = 15
         End
         Begin Table = "uo"
            Begin Extent = 
               Top = 6
               Left = 257
               Bottom = 95
               Right = 437
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_services'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_services'
go

