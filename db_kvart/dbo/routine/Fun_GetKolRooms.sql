-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetKolRooms]
(
	@build_id		INT
	,@roomtype_id	VARCHAR(10)
	,@Rooms			SMALLINT
)
/*
Используется для электронного паспорта (rep_build_pasport1)
подсчёт лиц-вых по кол-во комнат 
*/
RETURNS SMALLINT
AS
BEGIN

	DECLARE @ResultVar SMALLINT

	IF @Rooms = 7
		SELECT
			@ResultVar =
			COUNT(o.Occ)
		FROM dbo.OCCUPATIONS o
		JOIN dbo.FLATS f 
			ON o.flat_id = f.id
		WHERE f.bldn_id = @build_id
		AND o.STATUS_ID <> 'закр'
		AND COALESCE(o.rooms, 1) >= @Rooms
		AND o.ROOMTYPE_ID = @roomtype_id
	ELSE
		SELECT
			@ResultVar =
			COUNT(o.Occ)
		FROM dbo.OCCUPATIONS o 
		JOIN dbo.FLATS f 
			ON o.flat_id = f.id
		WHERE f.bldn_id = @build_id
		AND o.STATUS_ID <> 'закр'
		AND COALESCE(o.rooms, 1) = @Rooms
		AND o.ROOMTYPE_ID = @roomtype_id

	RETURN COALESCE(@ResultVar, 0)

END
go

