-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_load_sverka_occ]
(
	@tip_id SMALLINT
	,@FileIn   NVARCHAR(MAX)  -- лицевой,площадь
	,@CheckSaldo BIT = 0 -- сверять сальдо
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @File_TMP TABLE(
		occ int,
		total_sq decimal(9,2), 
		saldo decimal(9,2) default 0, 
		peni decimal(9,2) default 0
	)

	-- переносим данные из JSON
	INSERT @File_TMP
	(OCC
	,Total_sq
	,saldo
	,peni)
	SELECT
		occ
	   ,total_sq
	   ,saldo
	   ,peni
	FROM OPENJSON(@FileIn, '$.data')
	WITH (
		occ int '$."occ"',
		total_sq DECIMAL(9, 2) '$."total_sq"',
		saldo DECIMAL(9, 2) '$."saldo"',
		peni DECIMAL(9, 2) '$."peni"'
	) AS t

	DECLARE @Table_out TABLE(Occ INT, Result VARCHAR(50))
	
	INSERT INTO @Table_out(Occ,Result)
		SELECT ft.occ,'INSERT' 
		FROM @File_TMP AS ft
			LEFT JOIN dbo.Occupations AS o ON ft.occ=o.occ
		WHERE o.occ IS NULL

	INSERT INTO @Table_out(Occ,Result)
		SELECT ft.occ,'UPDATE' 
		FROM @File_TMP AS ft
		JOIN dbo.Occupations AS o ON ft.occ=o.occ
		WHERE o.total_sq<>ft.total_sq

	INSERT INTO @Table_out(Occ,Result)
		SELECT o.occ,'DELETE' 
		FROM dbo.Occupations AS o
			JOIN dbo.Flats as f ON f.id=o.flat_id
			JOIN dbo.Buildings as b ON b.id=f.bldn_id
		LEFT JOIN @File_TMP AS ft ON ft.occ=o.occ
		WHERE o.tip_id=@tip_id
		AND ft.occ IS NULL
		AND b.is_paym_build=1

	IF @CheckSaldo=1
		INSERT INTO @Table_out(Occ,Result)
			SELECT 
				ft.occ,
                CASE
                    WHEN o.SaldoAll <> ft.saldo THEN 'Сальдо в базе ' + str(o.SaldoAll, 9, 2) + ' <> ' +
                                                     ltrim(str(ft.saldo, 9, 2))
                        + ' = ' + str(o.SaldoAll - ft.saldo, 9, 2)
                    ELSE 'Пени в базе ' + str(o.Penalty_old, 9, 2) + '<>' + ltrim(str(ft.peni, 9, 2))
                        + ' = ' + str(o.Penalty_old - ft.peni, 9, 2)
                    END
		FROM @File_TMP AS ft
			JOIN dbo.Occupations AS o ON ft.occ=o.occ
		WHERE o.SaldoAll<>ft.saldo
			--OR o.Penalty_old<>ft.peni

	SELECT * FROM @Table_out

END
go

