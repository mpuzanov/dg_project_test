-- dbo.view_occ_all source

CREATE   VIEW [dbo].[view_occ_all]
AS

	SELECT c.[start_date]
		 , t1.*
		 , t1.Debt + ((t1.penalty_old_new+t1.penalty_added)+t1.penalty_value) AS SumPaymDebt -- к оплате (может быть отрицательной)
		 , f.bldn_id
		 , f.bldn_id AS build_id
		 , f.nom_kvr
		 , f.nom_kvr_sort
		 , f.floor
		 , f.id_nom_gis
		, o.occ_uid
		, o.address
		, CASE
			WHEN LEFT(o.prefix, 1) = '&' THEN REPLACE(o.prefix, '&', '')				
			ELSE f.nom_kvr + COALESCE(o.prefix,'')
		END AS nom_kvr_prefix
		
		, (t1.paymaccount-t1.paymaccount_peny) AS paymaccount_serv
		, ((t1.penalty_old_new+t1.penalty_added)+t1.penalty_value) AS penalty_itog

		, CASE WHEN ((((t1.saldo+t1.paid)+t1.Paid_minus)-(t1.paymaccount-t1.PaymAccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new))<0 
			THEN 0 
			ELSE (((t1.saldo+t1.paid)+t1.Paid_minus)-(t1.paymaccount-t1.PaymAccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new) 
		  END
		 AS whole_payment

		, CASE WHEN ((((t1.saldo+t1.paid)+t1.Paid_minus)-(t1.paymaccount-t1.PaymAccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new))>=0
			THEN 0
			ELSE (((t1.saldo+t1.paid)+t1.Paid_minus)-(t1.paymaccount-t1.PaymAccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new)
		  END
		  AS whole_payment_minus

	FROM (
		SELECT COALESCE(t.fin_id, ot.fin_id) AS fin_id
			 , occ
			 , tip_id
			 , flat_id
			 , ot.name as tip_name
			 , t.roomtype_id
			 , t.proptype_id
			 , t.status_id
			 , t.living_sq
			 , t.teplo_sq
			 , t.norma_sq
			 , t.total_sq
			 , t.saldo
			 , t.saldo_serv
			 , t.value
			 , t.discount
			 , t.compens
			 , t.added
			 , t.paymaccount
			 , t.paymaccount_peny
			 , t.paid
			 , t.paid_old
			 , t.paid_minus
			 , t.paid + t.paid_minus as paiditog
			 , t.penalty_old
			 , t.penalty_old_new
			 , t.penalty_added
			 , t.penalty_value
			 , t.penalty_calc
			 , t.penalty_old_edit
			 , t.debt
			 , t.kol_people
			 , t.socnaim
			 , t.jeu
			 , t.saldoall
			 , t.paymaccount_servall
			 , t.paidall
			 , t.addedall
			 , t.saldo_edit
			 , t.comments
			 , t.comments2
			 , t.comments_print
			 , t.id_jku_gis
			 , t.kolmesdolg
			 , t.kol_people_reg
			 , t.kol_people_all
			 , t.id_els_gis
			 , t.kol_people_owner
			 , t.data_rascheta
			 , t.date_start
			 , t.date_end
		FROM [dbo].[Occupations] AS t
			JOIN dbo.VOcc_types_access AS ot ON t.tip_id = ot.id

		UNION

		SELECT t.fin_id
			 , t.occ
			 , t.tip_id
			 , t.flat_id
			 , ot.name as tip_name
			 , t.roomtype_id
			 , t.proptype_id
			 , t.status_id
			 , t.living_sq
			 , t.teplo_sq
			 , t.norma_sq
			 , t.total_sq
			 , t.saldo
			 , t.saldo_serv
			 , t.value
			 , t.discount
			 , t.compens
			 , t.added
			 , t.paymaccount
			 , t.paymaccount_peny
			 , t.paid
			 , t.paid_old
			 , t.paid_minus
			 , t.paid + t.paid_minus as paiditog
			 , t.penalty_old
			 , t.penalty_old_new
			 , t.penalty_added
			 , t.penalty_value
			 , t.penalty_calc
			 , t.penalty_old_edit
			 , t.debt
			 , t.kol_people
			 , t.socnaim
			 , t.jeu
			 , t.saldoall
			 , t.paymaccount_servall
			 , t.paidall
			 , t.addedall
			 , t.saldo_edit
			 , t.comments
			 , t.comments2
			 , t.comments_print
			 , t.id_jku_gis
			 , t.kolmesdolg
			 , t.kol_people_reg
			 , t.kol_people_all
			 , t.id_els_gis
			 , t.kol_people_owner
			 , t.data_rascheta
			 , t.date_start
			 , t.date_end
		FROM dbo.Occ_history AS t 
			JOIN dbo.VOcc_types_all_access AS ot ON t.tip_id = ot.id
				AND t.fin_id = ot.fin_id
	) AS t1
		JOIN dbo.Flats AS f 
			ON t1.flat_id = f.id
		JOIN dbo.Calendar_period AS c 
			ON t1.fin_id=c.fin_id
		JOIN dbo.Occupations AS o 
			ON t1.occ = o.occ;
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
         Configuration = "(V (2) )"
      End
      ActivePaneConfig = 14
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
      PaneHidden = 
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
', 'SCHEMA', 'dbo', 'VIEW', 'view_occ_all'
go

exec sp_addextendedproperty 'MS_DiagramPaneCount', 1, 'SCHEMA', 'dbo', 'VIEW', 'view_occ_all'
go

