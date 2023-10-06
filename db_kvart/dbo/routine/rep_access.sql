CREATE   PROCEDURE [dbo].[rep_access] 
(
@user_id SMALLINT
)
AS

SET NOCOUNT ON


SELECT u.id,
      u.Initials AS Initials,
       gm.group_id,
       ug.name AS gr_name,
       op.op_id, 
       op.name AS op_name,
       REPLICATE(' ',150) AS JeuStr
INTO #TempUser
FROM dbo.users AS u ,
     dbo.group_membership AS gm ,
     dbo.user_groups AS ug ,
     dbo.operations AS op ,
     dbo.group_authorities AS ga
WHERE gm.user_id=u.id AND
      ug.group_id=gm.group_id AND
      ug.group_id=ga.group_id AND
      ga.op_id=op.op_id
      AND gm.user_id=COALESCE(@user_id,gm.user_id)
 
ORDER BY Initials, group_no, op_no

DECLARE @id1 INT, @group VARCHAR(10), @oper VARCHAR(10)
DECLARE table_curs CURSOR FOR 
   SELECT id, group_id, op_id FROM #TempUser
OPEN table_curs
FETCH NEXT FROM table_curs INTO @id1, @group, @oper
WHILE (@@FETCH_STATUS=0)
BEGIN
	DECLARE @JeuStr VARCHAR(150)=''

	SELECT @JeuStr=@JeuStr+LTRIM(STR(area_id))+',' -- Участки
	FROM dbo.allowed_areas AS al,
		 dbo.group_authorities AS ga
	WHERE al.user_id=@id1 AND
		  al.group_id=@group AND
		  al.op_id=@oper AND
		  ga.op_id=al.op_id AND
		  ga.group_id=@group AND
		  ga.areatype_id='тех!'

	SET @JeuStr=LTRIM(@JeuStr)
	IF @JeuStr=''               -- Районы
	BEGIN
		SELECT @JeuStr=@JeuStr+LTRIM(div.name)+','
		FROM dbo.allowed_areas AS al,
			 dbo.group_authorities AS ga,
			 dbo.divisions AS div
		WHERE al.user_id=@id1 AND
			  al.group_id=@group AND
			  al.op_id=@oper AND
			  ga.op_id=al.op_id AND
			  ga.group_id=@group AND
			  ga.areatype_id='отд!' AND
			  div.id=al.area_id
	END

	SET @JeuStr=LTRIM(@JeuStr)
	IF @JeuStr=''               -- Районы
	BEGIN
		SELECT @JeuStr='Все данные! '
		FROM dbo.allowed_areas AS al,
			 dbo.group_authorities AS ga
		WHERE al.user_id=@id1 AND
			  al.group_id=@group AND
			  al.op_id=@oper AND
			  ga.op_id=al.op_id AND
			  ga.group_id=@group AND
			  ga.areatype_id='все!'
	END

	IF @JeuStr<>''
	BEGIN
	  SET @JeuStr=SUBSTRING(@JeuStr,1,LEN(@JeuStr)-1)
	  UPDATE #TempUser
	  SET JeuStr=@JeuStr
	  WHERE id=@id1 AND
		  group_id=@group AND
		  op_id=@oper
	END
   FETCH NEXT FROM table_curs INTO @id1, @group, @oper
END
CLOSE table_curs
DEALLOCATE table_curs

SELECT Initials, gr_name, op_name, JeuStr, id
FROM #TempUser AS u

DROP TABLE #TempUser
go

