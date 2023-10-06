CREATE   PROCEDURE [dbo].[adm_div_show]
(
    @town_id SMALLINT = NULL
)
AS
/*
Вывод списка районов
*/

	SET NOCOUNT ON

	SELECT d.id
		  ,d.name
		  ,d.bank_id
		  ,d.name2
		  ,d.name3
		  ,d.bank_account
		  ,d.town_id
		  ,t.name as town_name
	FROM
		dbo.Divisions as d
		LEFT JOIN dbo.Towns as t ON
			d.town_id=t.ID
	WHERE
		(@town_id IS NULL OR town_id = @town_id)
go

