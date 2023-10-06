-- dbo.view_paycoll_orgs source

CREATE   VIEW [dbo].[view_paycoll_orgs]
AS
SELECT
	po.id
	,po.fin_id
	,po.bank
	,po.vid_paym
	,po.comision
	,po.ext
	,po.description
	,po.data_edit
	,po.user_edit
	,po.user_id
	,b.short_name AS bank_name
	,pt.name AS tip_paym
    ,pt.is_storno
	,pt.peny_no
	,b.id AS bank_id
	,pt.id AS tip_paym_id
	,po.sup_processing
	,b.is_bank
	,po.paying_order_metod
	,po.paycoll_uid
	,po.bank_uid
	,b.visible
FROM dbo.Paycoll_orgs AS po
INNER JOIN (SELECT
		su.sysuser
		,uot.ONLY_PAY_ORGS
	FROM (SELECT
			SUSER_SNAME() AS SYSUSER) AS su
	LEFT OUTER JOIN dbo.Users_pay_orgs AS uot
		ON su.sysuser = uot.sysuser) AS uo
	ON po.ext = COALESCE(uo.ONLY_PAY_ORGS, po.ext)
	AND system_user = uo.sysuser
INNER JOIN dbo.Bank AS b
	ON po.bank = b.id
INNER JOIN dbo.Paying_types	pt
	ON po.vid_paym = pt.id;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[48] 4[14] 2[6] 3) )"
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
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 223
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "uo"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 95
               Right = 419
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 96
               Left = 245
               Bottom = 235
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PAYING_TYPES"
            Begin Extent = 
               Top = 6
               Left = 457
               Bottom = 125
               Right = 626
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
         Alias = 1290
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_paycoll_orgs'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_paycoll_orgs'
go

