CREATE   PROCEDURE [dbo].[rep_flatcard_death]
(
	@id1	INT -- код человека
	,@Date1	DATETIME	= NULL-- на какую дату выдавать
)
AS
	/*
	
	Выдаем список людей проживающих
	с заданным человеком на конкретную дату
	
	exec rep_flatcard_death 149805
	*/
	SET NOCOUNT ON

	DECLARE @occ1 INT

	IF @Date1 IS NULL
		SET @Date1 = current_timestamp

	SELECT
		@occ1 = occ
	FROM dbo.PEOPLE
	WHERE id = @id1

	SELECT
		p.id
		,p.fio
		,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Д', CASE WHEN sex = 1 THEN 'МУЖ' ELSE CASE WHEN sex = 0 THEN 'ЖЕН' ELSE NULL END END) AS FIOdat
		,CASE p.Fam_id
			WHEN '????' THEN ''
			ELSE f.name
		END  AS Fam
		,p.Birthdate
		,p.DateReg
		,p.DateDel
		,CASE
			WHEN f.id = 'отвл' THEN 0
			WHEN p.DateDel IS NULL THEN 1
			ELSE 2
		END AS sort
	FROM dbo.VPeople AS p
	JOIN dbo.Fam_relations AS f
		ON p.Fam_id = f.id
	WHERE 
		occ = @occ1
		AND p.id <> @id1
		AND DateReg IS NOT NULL
		AND DateReg <= @Date1
		AND COALESCE(DateDel, current_timestamp) >= @Date1
		--AND p.Status2_id IN ('пост')
	ORDER BY sort, DateDel DESC
go

