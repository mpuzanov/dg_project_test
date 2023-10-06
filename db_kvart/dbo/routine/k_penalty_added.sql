CREATE   PROCEDURE [dbo].[k_penalty_added]
(
	  @occ1 INT
	  ,@fin_id SMALLINT = NULL
)
AS
	/*
	Показываем Разовые по пени

	exec k_penalty_added 30003
	exec k_penalty_added 30003, 232

	*/

	SET NOCOUNT ON
	SET LANGUAGE Russian

	SELECT cp.StrFinPeriod AS 'Фин.период'
		 , pa.occ AS 'Лицевой'
		 , pa.value_added AS 'Сумма'
		 , pa.doc AS 'Документ'
		 , u.Initials AS 'Пользователь'
		 , CONVERT(VARCHAR(10), pa.date_edit, 104) AS 'Дата'
		 --, pa.fin_id AS fin_id
	FROM dbo.Peny_added pa
		JOIN dbo.Users AS u  ON pa.user_edit = u.login
		JOIN dbo.Calendar_period cp ON cp.fin_id = pa.fin_id
	WHERE pa.occ = @occ1
		AND (pa.fin_id = @fin_id OR @fin_id IS NULL)
	ORDER BY pa.fin_id DESC
go

