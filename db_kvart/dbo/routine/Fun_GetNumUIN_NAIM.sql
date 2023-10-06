CREATE   FUNCTION [dbo].[Fun_GetNumUIN_NAIM]
(
	@occ		INT
	,@fin_id	SMALLINT
)
RETURNS VARCHAR(25)
AS
BEGIN
	/*
	
	Функция формирования уникального начисления
	
	select dbo.Fun_GetNumUIN_NAIM(45321,170)    -- 0320508500000453211905018
	select dbo.Fun_GetNumUIN_NAIM(85607809,169) -- 0320508500856078091905018

по УИН: 
(1-8 символ): УРН участника, сформировавшего начисление. УРН указывается в десятичном представлении. Для этого его необходимо предварительно перевести из шестнадцатиричного представления и десятичное.
Например, УРН участника равен значению <aa11b4>; после перевода в десятичное представление получается <11145652>. Если при переводе УРН участника в десятичное представление получается менее восьми символов, то значение дополняется нулями слева до 8 цифр.
(9-24 символ):Уникальный номер начисления - 16 цифр. Алгоритм формирования, обеспечивающий уникальность номера, 
определяется информационной системой.
(25 символ): Контрольный разряд. Алгоритм расчета описан в разделе 3.1.3.

	*/
	DECLARE	@uin	VARCHAR(25)
			--,@URN	VARCHAR(8)	= '00008277'  --код организации(УРН участника) в 16 рич.системе = 002055
			,@URN	VARCHAR(8)	= '03205085'  --код организации(УРН участника) в 16 рич.системе = 30E7DD

	-- 8 знаков код орг
	-- 10 зн лицевой счёт
	-- 6 зн дата

	SELECT
		--@uin = ('%s%010i%i%02i01', @URN, @occ, 19, 05)
		@uin = CONCAT(@URN, dbo.Fun_AddLeftZero(@occ,10),  '1905','01')
	FROM dbo.Global_values gv
	WHERE gv.fin_id = @fin_id
	
	RETURN dbo.Fun_GetNumUIN25(@uin)

END
go
