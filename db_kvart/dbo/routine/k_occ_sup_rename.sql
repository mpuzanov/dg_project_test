CREATE   PROCEDURE [dbo].[k_occ_sup_rename]
(
    @occ_sup_old INT,
    @occ_sup_new INT,
    @occ INT
)
AS
	/*

  Процедура переименования лицевого счета поставщика
  
*/
	SET NOCOUNT ON
	SET XACT_ABORT ON


	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF EXISTS (SELECT *
			   FROM dbo.OCC_SUPPLIERS 
			   WHERE occ_sup = @occ_sup_new)
	BEGIN
		RAISERROR ('Лицевой %i поставщика уже существует!', 16, 1, @occ_sup_new)
		RETURN
	END

	BEGIN TRAN

	UPDATE dbo.OCC_SUPPLIERS 
	SET occ_sup = @occ_sup_new
	WHERE occ_sup = @occ_sup_old
	AND occ=@occ
	AND occ_sup <> @occ_sup_new

	UPDATE dbo.CESSIA 
	SET occ_sup = @occ_sup_new
	WHERE occ_sup = @occ_sup_old
	AND occ=@occ

	UPDATE dbo.PENY_ALL 
	SET occ = @occ_sup_new
	WHERE occ = @occ_sup_old
	AND occ=@occ

	UPDATE dbo.PENY_DETAIL 
	SET occ = @occ_sup_new
	WHERE occ = @occ_sup_old
	AND occ=@occ

	COMMIT TRAN
go

