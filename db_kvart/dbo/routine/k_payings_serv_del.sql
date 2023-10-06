CREATE   PROCEDURE [dbo].[k_payings_serv_del]
(
	  @paying_id INT
)
AS
	/*
	
	Процедура удаления раскидки по услугам 
	
	*/
	SET NOCOUNT ON

	DELETE FROM dbo.Paying_serv WITH (ROWLOCK)
	WHERE paying_id = @paying_id
go

