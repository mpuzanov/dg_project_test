CREATE   procedure [dbo].[b_UpdateSupRaschet]
(
    @filedbf_id INT
)
as
begin

    update bd
    set sup_id=os.sup_id, sch_lic=os.occ_sup
    from dbo.Bank_Dbf as bd
    join dbo.Occ_Suppliers as os 
		on bd.occ=os.occ 
			and bd.rasschet=os.rasschet
    join dbo.Occupations as o 
		on os.occ = o.Occ
    join dbo.Occupation_Types as ot 
		ON o.tip_id = ot.id and os.fin_id=ot.fin_id
    where bd.filedbf_id=@filedbf_id
        and bd.rasschet is not null
        and pack_id is null
    ;

end
go

