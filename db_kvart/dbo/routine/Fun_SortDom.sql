CREATE   FUNCTION [dbo].[Fun_SortDom] (@nom_dom varchar(20))  
RETURNS varchar(20) AS  
BEGIN 
/*
  Функция сортирует дома и квартиры(цифры с буквами)
  ORDER BY dbo.Fun_SortDom(b.nom_dom)
  ORDER BY dbo.Fun_SortDom(f.nom_kvr)

  select dbo.Fun_SortDom('123A')
  select dbo.Fun_SortDom('123456789ABC')
  select dbo.Fun_SortDom('12345678901234567ABC')

  declare @t table(nom_dom varchar(20))
  insert into @t(nom_dom)
  VALUES ('12345678901234569ABC'), ('12345678901234567ABC'), ('12345678901234568ABC'),
  ('1234567890129ABC'), ('1234567890125ABC'), ('1234567890124ABC')
  select nom_dom, dbo.Fun_SortDom(nom_dom) from @t ORDER BY dbo.Fun_SortDom(nom_dom)

*/
RETURN 
  case
    when Patindex('%[^0-9]%', @Nom_dom)=0
    then Space(20-DataLength(Rtrim(@Nom_dom)))+@Nom_dom
    else Space(21-Patindex('%[^0-9]%', @Nom_dom))+@Nom_dom
  end
END
go

