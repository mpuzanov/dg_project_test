CREATE   PROCEDURE [dbo].[k_telephon_save]
(
	  @occ1 INT
	, @telephon1 BIGINT
)
AS
	/*
		сохранение номера телефона в лицевом
		exec k_telephon_save @occ1=1000053070, @telephon1=123456
	*/
	SET NOCOUNT ON

	UPDATE o 
	SET telephon = CASE
                       WHEN @telephon1 = 0 THEN NULL
                       ELSE @telephon1
        END
	FROM dbo.Occupations AS o
	WHERE o.Occ = @occ1
go

