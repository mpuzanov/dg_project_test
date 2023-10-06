CREATE   PROCEDURE [dbo].[k_Find_PuFromOcc]
(
	@occ INT -- лицевой
	,@serial_number VARCHAR(20)
	,@counter_id INT = NULL OUT 
)
AS
	/*
	Находим ПУ по лицевому счёту и серийному номеру

	дата создания: 29.12.2020
	автор: Пузанов М.А.
	
	exec dbo.k_Find_PuFromOcc @occ=680003552,@serial_number=16023665
	exec dbo.k_Find_PuFromOcc @occ=85000078,@serial_number=16023665

	*/
	SET NOCOUNT ON

	SELECT @occ = dbo.Fun_GetFalseOccIn(@occ), @counter_id = NULL;

	SELECT 
		@counter_id=c.id
	FROM dbo.Counters as c
		JOIN dbo.Occupations as o ON 
			c.flat_id=o.flat_id
	WHERE o.occ=@occ
		and c.serial_number=@serial_number
		and c.date_del is null;

	if @counter_id is NULL  -- проверим по поставщику
		SELECT 
			@counter_id=c.id
		FROM dbo.Counters as c			
			JOIN dbo.Occupations as o ON 
				c.flat_id=o.flat_id
			JOIN dbo.Occ_Suppliers AS os ON 
				o.occ=os.occ 
				AND os.fin_id=o.fin_id
		WHERE 
			os.occ_sup=@occ
			and c.serial_number=@serial_number
			and c.date_del is null;

	SELECT @counter_id as id;
go

