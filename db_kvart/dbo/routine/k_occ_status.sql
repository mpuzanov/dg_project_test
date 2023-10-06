CREATE   PROCEDURE [dbo].[k_occ_status]
(
	@occ1 INT
)
AS
	--
	--  Проверяем статус лицевого счета (откр, своб, закрыт)
	--
	SET NOCOUNT ON

	DECLARE	@status_id1	VARCHAR(10)
			,@KolP		INT
			,@fin_current SMALLINT
	SELECT
		@status_id1 = Status_id, @fin_current=o.fin_id
	FROM dbo.Occupations AS o 
	WHERE occ = @occ1


	CREATE TABLE #p1
	(
		fin_id		SMALLINT
		,occ		INT
		,owner_id	INT
	    ,people_uid UNIQUEIDENTIFIER
		,Lgota_id	SMALLINT
		,Status_id	TINYINT
		,Status2_id	VARCHAR(10) COLLATE database_default
		,Birthdate	SMALLDATETIME
		,Doxod		DECIMAL(8, 2)
		,dop_norma	TINYINT
		,data1		SMALLDATETIME
		,data2		SMALLDATETIME
		,kolday		TINYINT
		,DateEnd	SMALLDATETIME
	)

	INSERT INTO #p1 EXEC k_PeopleFin	@occ1
										,@fin_current

	SELECT
		@KolP = COUNT(p.owner_id)
	FROM #p1 AS p


	--select @KolP=count(p.id) FROM people as p where occ=@occ1 and del=0

	IF @KolP IS NULL
		SET @KolP = 0

	IF (@status_id1 = 'откр')
		AND (@KolP = 0)
	BEGIN
		UPDATE dbo.Occupations
		SET Status_id = 'своб'
		WHERE occ = @occ1
	END

	IF (@status_id1 = 'своб')
		AND (@KolP > 0)
	BEGIN
		UPDATE dbo.Occupations 
		SET Status_id = 'откр'
		WHERE occ = @occ1
	END
go

