create index occ
    on Paym_list (occ, sup_id, fin_id) include (paymaccount, subsid_only, saldo, paymaccount_peny, penalty_serv,
                                                penalty_old)
go

