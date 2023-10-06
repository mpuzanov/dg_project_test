-- dbo.view_suppliers_all source

CREATE   VIEW [dbo].[view_suppliers_all]
AS
	SELECT o.id
		 , o.name
		 , o.adres
		 , o.telefon
		 , o.fio
		 , o.bank_account
		 , o.id_accounts
		 , o.account_one
		 , o.first_occ
		 , o.penalty_calc
		 , o.LastPaym
		 , o.synonym_name
		 , o.inn
		 , o.type_sum_intprint
		 , o.ogrn
		 , o.kpp
		 , o.email
		 , o.tip_org_for_account
		 , o.str_account1
		 , o.web_site
		 , o.adres_fact
		 , o.rezhim_work
		 , o.penalty_metod
		 , o.LastStrAccount
		 , o.tip_occ
		 , o.account_rich
		 , o.sup_uid
	FROM dbo.Suppliers_all AS o
		INNER JOIN (
			SELECT su.SYSUSER
				 , uot.ONLY_SUP_ID
			FROM (SELECT SUSER_SNAME() AS SYSUSER) AS su
				LEFT OUTER JOIN dbo.Users_sup AS uot ON su.SYSUSER = uot.SYSUSER
		) AS uo ON o.id = COALESCE(uo.ONLY_SUP_ID, o.id);
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[20] 3) )"
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
         Begin Table = "o"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 200
               Right = 222
            End
            DisplayFlags = 280
            TopColumn = 13
         End
         Begin Table = "uo"
            Begin Extent = 
               Top = 6
               Left = 260
               Bottom = 96
               Right = 429
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_suppliers_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_suppliers_all'
go

