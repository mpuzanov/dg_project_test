-- dbo.view_bank_format source

CREATE   VIEW [dbo].[view_bank_format]
AS
	SELECT bf.*
		 , CONCAT(
		 'D', LTRIM(STR(DATA_PLAT_NO))
		 ,'L', LTRIM(STR(LIC_NO))
		 , CASE WHEN (ADRES_NO IS NULL) THEN '' ELSE CONCAT('A' , LTRIM(STR(COALESCE(ADRES_NO, 0)))) END
		 , 'S' , LTRIM(STR(SUMMA_NO)) 
		 , CASE WHEN (COMMIS_NO IS NULL) THEN '' ELSE CONCAT('C' , LTRIM(STR(COALESCE(COMMIS_NO, 0)))) END
		 , CASE WHEN (RASCH_NO IS NULL) THEN '' ELSE CONCAT('R' , LTRIM(STR(COALESCE(RASCH_NO, 0)))) END
		 , CASE WHEN (FIO_NO IS NULL) THEN '' ELSE CONCAT('F' , LTRIM(STR(COALESCE(FIO_NO, 0)))) END
		 ) AS format_str
	FROM dbo.Bank_format AS bf
		INNER JOIN (
			SELECT su.SYSUSER
				 , uot.ONLY_PAY_ORGS
			FROM (SELECT SUSER_SNAME() AS SYSUSER) AS su
				LEFT OUTER JOIN dbo.Users_pay_orgs AS uot ON su.SYSUSER = uot.SYSUSER
		) AS uo ON bf.EXT_BANK = COALESCE(uo.ONLY_PAY_ORGS, bf.EXT_BANK)
			AND system_user = uo.SYSUSER;
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
         Begin Table = "bf"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 210
               Right = 231
            End
            DisplayFlags = 280
            TopColumn = 14
         End
         Begin Table = "uo"
            Begin Extent = 
               Top = 6
               Left = 269
               Bottom = 96
               Right = 443
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_bank_format'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_bank_format'
go

