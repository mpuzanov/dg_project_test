-- dbo.view_buildings source

-- dbo.view_buildings source

CREATE   view [dbo].[view_buildings]
as
	select b.id
		, sec.name as sector_name
		, vt.name as tip_name
		, d.name as div_name
		, s.name as street_name
		, b.nom_dom
		, case
				when dbo.strpos('/', b.nom_dom)>0 then substring(b.nom_dom, 1, dbo.strpos('/', b.nom_dom) - 1)
				else b.nom_dom
			end as nom_dom_without_korp
		, case
				when dbo.strpos('/', b.nom_dom)>0 then substring(b.nom_dom, dbo.strpos('/', b.nom_dom) + 1, 12)
				else ''
			end as korp
		, concat(s.name , ' д.' , b.nom_dom) as adres		
		, s.short_name as street_short_name
		, s.socr_name as socr_street
		, coalesce(b.seria, '-') as seria
		, coalesce(b.godp, 0) as godp
		, b.street_id
		, b.sector_id
		, b.div_id
		, b.tip_id
		, b.levels
		, b.balans_cost
		, b.material_wall
		, b.comments
		, b.standart_id
		, coalesce(build_total_sq, 0) as total_sq
		, b.old
		, b.kolpodezd
		, b.dog_bit
		, bm.name as material_name
		, b.index_id
		, st.name as standart_name
		, b.bank_account
		, b.town_id
		, b.court_id
		, b.collector_id
		, case
			when b.id_accounts is not null then b.id_accounts
			else vt.id_accounts
		  end as id_accounts
		, b.index_postal
		, tw.[name] as town_name
		, b.date_start
		, b.date_end
		, b.norma_gkal
		, b.arenda_sq
		, b.is_paym_build
		, coalesce(b.build_total_sq, 0) as build_total_sq
		, coalesce(b.build_total_area, 0) as build_total_area
		, b.nom_dom_sort
		, b.opu_sq
		, b.opu_sq_elek
		, b.opu_sq_otop
		, b.opu_tepl_kol
		, b.vid_blag
		, b.is_lift
		, b.is_boiler
		, b.fin_current
		, b.build_type
		, b.odn_big_norma
		, b.kod_fias
		, b.kod_gis
		, b.id_nom_dom_gis
		, s.kod_fias as street_fias
		, b.cadastralnumber
		, b.levels_underground
		, b.kultura
		, b.levels_min
		, b.build_uid
		, case when(coalesce(b.oktmo, '') = '') then tw.oktmo else b.oktmo end as oktmo
		, o.kolflats as kolflats
		, o.living_sq as living_sq
		, o.kollic as kollic
		, o.kolpeople as kolpeople
		, case 
			when b.soi_is_transfer_economy=cast(1 as bit) then b.soi_is_transfer_economy
			else vt.soi_is_transfer_economy 
		end as soi_is_transfer_economy
		, concat(s.name , b.nom_dom_sort) as sort_dom
	from dbo.buildings as b
		inner join dbo.vstreets as s  
			on b.street_id = s.id
		inner join dbo.vocc_types as vt
			on b.tip_id = vt.id
		left outer join dbo.towns as tw 
			on b.town_id = tw.id
		left outer join dbo.divisions as d 
			on b.div_id = d.id
		left outer join dbo.sector as sec 
			on b.sector_id = sec.id
		left outer join dbo.standart as st 
			on b.standart_id = st.id
		left outer join dbo.bldn_materials as bm 
			on b.material_wall = bm.id
		cross apply (
			select count(distinct f.id) as kolflats
				 , sum(o.living_sq) as living_sq
				 , count(o.occ) as kollic
				 , sum(o.kol_people) as kolpeople
			from dbo.flats as f 
				inner join dbo.occupations as o  on o.flat_id = f.id
			where (f.bldn_id = b.id)
				and (o.status_id <> 'закр')
		) as o;
go

exec sp_addextendedproperty 'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[51] 4[18] 2[21] 3) )"
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
         Configuration = "(H (1[50] 4[19] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[55] 2) )"
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
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "b"
            Begin Extent = 
               Top = 0
               Left = 23
               Bottom = 300
               Right = 184
            End
            DisplayFlags = 280
            TopColumn = 13
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 237
               Bottom = 107
               Right = 398
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 635
               Bottom = 122
               Right = 796
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "TOWNS"
            Begin Extent = 
               Top = 108
               Left = 218
               Bottom = 212
               Right = 387
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 109
               Left = 492
               Bottom = 225
               Right = 653
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sec"
            Begin Extent = 
               Top = 94
               Left = 803
               Bottom = 210
               Right = 964
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "STANDART"
            Begin Extent = 
               Top = 197
               Left = 655
               Bottom = 310
               Right = 856
            End
            DisplayFlags = 280
            TopColumn = 0
', 'SCHEMA', 'dbo', 'VIEW', 'view_buildings'
go

exec sp_addextendedproperty 'MS_DiagramPane2', N'         End
         Begin Table = "BLDN_MATERIALS"
            Begin Extent = 
               Top = 227
               Left = 264
               Bottom = 328
               Right = 425
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
      Begin ColumnWidths = 29
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
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 4695
         Alias = 1755
         Table = 1845
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_buildings'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 2, 'SCHEMA', 'dbo', 'VIEW', 'view_buildings'
go

