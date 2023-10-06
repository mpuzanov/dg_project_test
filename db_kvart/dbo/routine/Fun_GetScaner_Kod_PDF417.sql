CREATE   FUNCTION [dbo].[Fun_GetScaner_Kod_PDF417] 
( @occ1 bigint
 ,@service_id1 VARCHAR(10)=null -- код услуги
 ,@fin_id1 smallint=null
 ,@summa1 decimal(9,2)= 0 -- сумма к оплате
 ,@address varchar(50) = ''
 ,@Initials varchar(50) = ''
 ,@name  varchar(50) = ''
 ,@bik varchar(9)=null
 ,@rschet varchar(20)=null
 ,@vid_serv_bank bigint=null
)  
RETURNS varchar(1000) AS  
/*
Дата создания: 01.02.2010
Автор изменения: Пузанов М.А.

Описание используемого штрих-кода в счетах-извещениях
Формат  - двух мерный штрих-код например PDF417

*/
BEGIN 
	declare 
	@Kod1 varchar(1000), 
	@kod varchar(2),
	@strschtl varchar(25),
	@start_date smalldatetime,
	@mes varchar(2),  
	@strsumma1 varchar(8),
	@tip_id1 smallint

	if @vid_serv_bank is null set @vid_serv_bank=0
	if @rschet is null set @rschet='00000000000000000000'
	if @bik is null set @bik='000000000'

	if @occ1<999999
	BEGIN    
	if @service_id1 is not null  -- по счетчику
	begin 
	  set @kod='00'
	  declare @service_kod tinyint
	  select @service_kod=service_kod from dbo.SERVICES  where id=@service_id1
	  set @kod=dbo.Fun_AddLeftZero(@service_kod,2)
	end
	set @strschtl=ltrim(str(@occ1))
	END
	ELSE
	BEGIN
	set @strschtl=ltrim(str(@occ1))
	END

	-- Определяем тип жилого фонда
	select @tip_id1=tip_id FROM OCCUPATIONS as o where occ=@occ1
	if @tip_id1=1
	set @strschtl='ЕД.ЛИЦЕВОЙ: '+@strschtl
	else
	set @strschtl='ЛИЦ. СЧЕТ: '+@strschtl


	select @mes='00'
	set @strsumma1=''

	if  @fin_id1 is not null
	begin
	select @start_date=start_date from dbo.GLOBAL_VALUES where fin_id=@fin_id1
	if @start_date is null
	begin
	  select @start_date=start_date from dbo.GLOBAL_VALUES  where closed=0
	end

	set @mes=DatePart(Month,@start_date)
	set @mes=dbo.Fun_AddLeftZero(@mes,2)
	end

	set @strsumma1=ltrim(str(@summa1,8,2))

	set @Kod1=@name+char(124)+@bik+char(124)+@rschet+char(124)+ltrim(str(@vid_serv_bank))
	set @Kod1=@Kod1+char(124)+@strschtl+'; АДРЕС: '+UPPER(rtrim(@address))+'; ПЕРИОД: '+@mes+'; ФИО: '+UPPER(rtrim(@Initials))
	set @Kod1=@Kod1+char(124)+@strsumma1+char(124)

	RETURN  @Kod1
END
go

