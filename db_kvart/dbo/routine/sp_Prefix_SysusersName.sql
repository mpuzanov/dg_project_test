/****************************************************************/ 
 
CREATE PROCEDURE [dbo].[sp_Prefix_SysusersName]
    @database_name       VARCHAR(123),	-- User specifies the database
    @old_sysusersname    VARCHAR(300),	-- User specifies the Old     sysusers.name
    @new_sysusersname    VARCHAR(300)         -- User specifies the New     Sysusers.name
AS
DECLARE @var varchar(500)
 
PRINT'************************************************'
PRINT'This procedure is ONLY to be used in conjuntion with the sp_SidMap procedure that 
is referenced in the Knowledge Base Article - Q240872'
PRINT''
PRINT'This procedure updates the sysusers table to a new name when an old name and 
new name is specified'
PRINT'************************************************'
PRINT''             
-- ERROR IF IN USER TRANSACTION --
IF @@trancount > 0
BEGIN
  RAISERROR(15289,-1,-1)
  RETURN (0)
END
      
-- Only an sa can run this procedure
IF ((SELECT suser_id()) <> 1)
BEGIN
  PRINT 'Error: Only the sa may run sp_Prefix_SysusersName'
  RETURN(0)
END
    
IF (@database_name IS NULL)
BEGIN
  PRINT 'Error: Pass the Database Name that was moved or restored, as the first parameter to the procedure'
  RETURN(0)
END
      
IF (@old_sysusersname IS NULL)
BEGIN
  PRINT 'Error: Pass the Old Sysusers.name that has the problem, as the second parameter to the procedure'
  RETURN(0)
END
      
IF (@new_sysusersname IS NULL)
BEGIN
  PRINT 'Error: Pass the New Sysusers.name to correct the problem, as the third parameter to the procedure'
  RETURN(0)
END
      
IF EXISTS( SELECT 1 FROM sysusers where name = @old_sysusersname )
BEGIN
  SELECT @var = 'UPDATE ' + @database_name + '..sysusers set name = ' +  
         ''''+ @new_sysusersname + '''' +' where name = ' + ''''+ @old_sysusersname + ''''
  EXEC (@var)
  PRINT'Successfully updated the user from ' + '''' + @old_sysusersname + '''' +  ' to ' + '''' + @new_sysusersname + ''''
  PRINT''
END
ELSE
BEGIN  
  PRINT'MSG ***: The username ' + ''''+ @old_sysusersname + '''' + ' does not exist in the database ' + '''' + @database_name + ''''
  PRINT'MSG ***: Make sure you specify the correct username.'
END
go

