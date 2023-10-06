CREATE   PROCEDURE [dbo].[adm_addbuild]
(
	  @tip_id1 SMALLINT
	, @street_id1 SMALLINT 
	, @nom_dom1 VARCHAR(12) 
	, @town_id SMALLINT = NULL
	, @id1 INT = NULL OUTPUT-- код нового дома (выходной параметр)
)
AS
	/*
		Добавляем новый дом
	
	DECLARE @RC int
	DECLARE @tip_id1 smallint
	DECLARE @street_id1 smallint
	DECLARE @nom_dom1 varchar(7)
	DECLARE @town_id smallint
	DECLARE @id1 int
	
	-- TODO: задайте здесь значения параметров.

EXECUTE @RC = [dbo].[adm_addbuild] 
   @tip_id1
  ,@street_id1
  ,@nom_dom1
  ,@town_id
  ,@id1 OUTPUT
GO
	
*/
	SET NOCOUNT ON

	DECLARE @sector_id1 SMALLINT
		  , @div_id1 SMALLINT
		  , @fin_current SMALLINT

	--select @id1=max(id) from buildings
	--select @id1=COALESCE(@id1,0)+1

	SELECT TOP (1) @sector_id1 = ID
	FROM dbo.Sector
	WHERE tip = @tip_id1;

	SELECT TOP (1) @div_id1 = ID
	FROM dbo.Divisions;

	SELECT @fin_current = fin_id
	FROM dbo.Occupation_Types
	WHERE ID = @tip_id1;

	IF @sector_id1 IS NULL
		SET @sector_id1 = 0;

	IF EXISTS (
			SELECT *
			FROM dbo.Buildings
			WHERE street_id = @street_id1
				AND nom_dom = @nom_dom1
				AND tip_id = @tip_id1
		)
	BEGIN
		RAISERROR ('В этом типе жилого фонда такой дом уже есть!', 16, 1)
		RETURN 1
	END

	INSERT INTO dbo.Buildings (street_id
							, nom_dom
							, sector_id
							, div_id
							, tip_id
							, fin_current
							, town_id)
	VALUES(@street_id1
		 , @nom_dom1
		 , @sector_id1
		 , @div_id1
		 , @tip_id1
		 , @fin_current
		 , COALESCE(@town_id, 1))

	SELECT @id1 = SCOPE_IDENTITY()
go

