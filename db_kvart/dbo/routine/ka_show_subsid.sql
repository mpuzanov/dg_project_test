CREATE   PROCEDURE [dbo].[ka_show_subsid]
(
	  @occ1 INT
)
AS
	--
	--  Процедура выдает разовые по субсидиям
	--  код услуги, краткое название, сумма(0)
	--
	SET NOCOUNT ON

	DECLARE @t1 TABLE (
		  id VARCHAR(10)
		, short_name CHAR(20)
		, calcvalue DECIMAL(9, 2)
		, VALUE DECIMAL(9, 2)
		, doc VARCHAR(50) DEFAULT NULL
		, doc_no VARCHAR(10) DEFAULT NULL
		, doc_date SMALLDATETIME DEFAULT NULL
	)

	INSERT INTO @t1
	SELECT s.id
		 , s.short_name
		 , 0
		 , 0
		 , ''
		 , ''
		 , NULL
	FROM dbo.View_services AS s
	WHERE s.is_subsid = 1
	ORDER BY s.service_no


	UPDATE @t1
	SET calcvalue = COALESCE(cs.VALUE, 0)   --coalesce(cs.value_subsid,0)
	FROM @t1 AS s
		LEFT JOIN dbo.Paym_list AS cs ON cs.occ = @occ1
			AND s.id = cs.service_id


	UPDATE @t1
	SET VALUE = COALESCE(ap.VALUE, 0)
	  , doc = COALESCE(ap.doc, '')
	  , doc_no = COALESCE(ap.doc_no, '')
	  , doc_date = ap.doc_date
	FROM @t1 AS s
		LEFT JOIN dbo.Added_Payments AS ap ON ap.occ = @occ1
			AND s.id = ap.service_id
			AND ap.add_type = 4 -- тип разового "возврат по субсидиям"

	SELECT *
	FROM @t1
go

