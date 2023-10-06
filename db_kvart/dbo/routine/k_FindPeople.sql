CREATE   PROCEDURE [dbo].[k_FindPeople]
(
	@owner_id1	INT
	,@p1		SMALLINT	= 1
)
AS
/*
	Поиск человека
	@p1=1  поиск по Ф.И.О
	   =2  поиск по паспорту
	
*/
	SET NOCOUNT ON

	IF @p1 = 1
	BEGIN
		DECLARE	@Last_name		VARCHAR(50)
				,@First_name	VARCHAR(30)
				,@Second_name	VARCHAR(30)

		SELECT
			@Last_name = Last_name
			,@First_name = First_name
			,@Second_name = Second_name
		FROM dbo.People
		WHERE id = @owner_id1

		SELECT
			o.occ
			,SUBSTRING(o.address, 1, 50) AS address
			,p.fio AS fio
			,p.birthdate AS birthdate
			,p.Del
			,p.DateDel
			,ps.short_name AS Status2 -- статус прописки
			,f.name AS Fam -- родственные отношения
			,doc.*
		FROM dbo.VPeople AS p 
		LEFT OUTER JOIN dbo.Iddoc AS doc
			ON p.id = doc.owner_id -- может паспортных данных нет
		JOIN dbo.Occupations AS o
			ON p.occ = o.occ
		JOIN dbo.Person_statuses AS ps
			ON p.Status2_id = ps.id
		JOIN dbo.Fam_relations AS f
			ON p.Fam_id = f.id
		WHERE Last_name LIKE @Last_name + '%'
			AND First_name LIKE @First_name + '%'
			AND Second_name LIKE @Second_name + '%'
		ORDER BY DateDel DESC

	END  -- if @p1=1

	IF @p1 = 2
	BEGIN
		DECLARE	@doc_no1		VARCHAR(12) -- номер документа
				,@passser_no1	VARCHAR(12) -- серия документа

		SELECT
			@doc_no1 = DOC_NO
			,@passser_no1 = PASSSER_NO
		FROM dbo.Iddoc
		WHERE owner_id = @owner_id1

		SELECT
			o.occ
			,SUBSTRING(o.address, 1, 50) AS address
			,p.fio
			,p.Birthdate
			,p.Del
			,p.DateDel
			,doc.*
		FROM dbo.VPeople AS p
		JOIN dbo.Occupations AS o
			ON p.occ = o.occ
		JOIN dbo.Iddoc AS doc
			ON doc.owner_id = p.id
		WHERE doc.DOC_NO = @doc_no1
			AND doc.PASSSER_NO = @passser_no1
		ORDER BY DateDel DESC

	END
go

