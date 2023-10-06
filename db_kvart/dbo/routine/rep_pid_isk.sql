-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_pid_isk]
(
	@pid_id INT
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		p.id
		,p.data_create --'Дата создания'
		,p.data_end -- 'Дата окончания'
		,p.summa --'Сумма'
		,p.kol_mes
		,p.sup_id
		,p.owner_id
		,o.address AS adres
		,dbo.Fun_InitialsFull(p.occ) AS Initials
		,dbo.Fun_GetGosposhlina(p.summa, 1) AS gosposhlina
		,SA.adres AS sup_adres
		,CASE
			WHEN COALESCE(SA.synonym_name, '') = '' THEN SA.name
			ELSE SA.synonym_name
		END AS sup_name
		,CASE
			WHEN COALESCE(OT.synonym_name, '') = '' THEN OT.name
			ELSE OT.synonym_name
		END AS tip_name
		,dbo.Fun_GetAdres(B.id, NULL, NULL) AS adres_build
		,B.dog_num
		,B.dog_date
		,B.dog_date_sobr
		,B.dog_date_protocol
		,B.dog_num_protocol
		,C.name AS court_name
		,C.Number_uch
	FROM dbo.PID AS p 
	JOIN dbo.OCCUPATIONS AS o 
		ON p.occ = o.occ
	JOIN dbo.OCCUPATION_TYPES AS OT 
		ON o.tip_id = OT.id
	JOIN dbo.FLATS AS F 
		ON o.flat_id = F.id
	JOIN dbo.BUILDINGS AS B
		ON F.bldn_id = B.id
	LEFT JOIN dbo.COURTS AS C 
		ON B.court_id = C.id
	LEFT JOIN dbo.SUPPLIERS_ALL AS SA
		ON p.sup_id = SA.id
	WHERE p.id = @pid_id

END
go

