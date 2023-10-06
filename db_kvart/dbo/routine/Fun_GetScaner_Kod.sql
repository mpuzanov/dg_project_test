CREATE   FUNCTION [dbo].[Fun_GetScaner_Kod] (@occ1 int, @fin_id1 smallint, @SumPaym decimal(9,2) )  
RETURNS varchar(25) AS  
BEGIN 
-- сейчас не используется
  declare @StrKod1 varchar(25), @start_date smalldatetime,
   @mes varchar(2), 
   @god varchar(4),  
   @strschtl varchar(7),
   @jeu smallint,
   @strjeu varchar(3),
   @eansum1 varchar(9),  
   @eansum2 varchar(2),
   @i tinyint
 
  select @start_date=start_date
  from GLOBAL_VALUES  where fin_id=@fin_id1
 
  select @jeu=b.sector_id
  from OCCUPATIONS as o ,
       FLATS as f ,
       BUILDINGS as b 
  where o.occ=@occ1
     and o.flat_id=f.id
     and f.bldn_id=b.id
 
  set @strjeu=dbo.Fun_AddLeftZero(@jeu,3)
  set @strschtl=dbo.Fun_AddLeftZero(@occ1,7)
  set @mes=DatePart(Month,@start_date)
  set @mes=dbo.Fun_AddLeftZero(@mes,2)
  set @god=Substring(ltrim(Str(DatePart(Year,@start_date))),3,2)
 
  set @eansum1=convert(varchar(9),@SumPaym)
  set @i=len(@eansum1)
  set @eansum2=Substring(@eansum1,@i-1,2)
  set @eansum1=Substring(@eansum1,1,@i-3)   
  set @eansum1=dbo.Fun_AddLeftZero(@eansum1,7)
 
 
  set @StrKod1='0'+@mes+@god+@strjeu+@strschtl+@eansum1+@eansum2
  RETURN  @StrKod1
END
go

