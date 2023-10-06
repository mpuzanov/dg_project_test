-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[k_email_acc_add]
(
	@occ		INT
   ,@fin_id		SMALLINT
   ,@fileName   VARCHAR(50)
   ,@email		VARCHAR(50)	  = NULL
   ,@SumPaym	DECIMAL(9, 2) = NULL
   ,@dir		VARCHAR(200)  = NULL -- каталог где сохранялись квитанции
   ,@account_id INT			  = NULL -- код квитанции
)
AS
/*

exec k_email_acc_add 680000210,182,'20170301_680000210_42.PDF','Akb559000@mail.ru'

*/
BEGIN
	SET NOCOUNT ON;

	MERGE dbo.ACCOUNT_EMAIL AS ae USING (SELECT
			@occ AS occ
		   ,@fin_id AS fin_id
		   ,@fileName AS fileName
		   ,@email AS email
		   ,@SumPaym AS SumPaym
		   ,@dir AS dir
		   ,COALESCE(@account_id,0) AS account_id) AS t_new
	ON ae.fin_id = t_new.fin_id
		AND ae.occ = t_new.occ
		AND ae.[fileName] = t_new.fileName
		AND ae.account_id = t_new.account_id
	WHEN MATCHED
		-- изменяем информацию
		THEN UPDATE
			SET dateCreate = current_timestamp
			   ,email	   = t_new.email
			   ,email_out  = 0
			   ,SumPaym	   = t_new.SumPaym
			   ,sysuser	   = system_user
			   ,dir		   = t_new.dir
	WHEN NOT MATCHED
		-- Добавляем информацию 
		THEN INSERT
			(occ
			,fin_id
			,[fileName]
			,dateCreate
			,email
			,email_out
			,SumPaym
			,sysuser
			,dir
			,account_id)
			VALUES (t_new.occ
				   ,t_new.fin_id
				   ,t_new.fileName
				   ,current_timestamp
				   ,t_new.email
				   ,0
				   ,t_new.SumPaym
				   ,system_user
				   ,t_new.dir
				   ,t_new.account_id)
	;




END
go

