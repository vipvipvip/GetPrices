USE [IDToDSN_DKC]
GO
/****** Object:  StoredProcedure [dbo].[csp_ReadCSV]    Script Date: 11/26/2014 6:26:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







ALTER PROCEDURE [dbo].[csp_ReadCSV]
	(
	@filename nvarchar(255),
	@dbDir nvarchar(255)='c:\',
	@cols nvarchar(255) = '*',
	@whereclause nvarchar(255)='1=1',
	@fmtfile nvarchar(255) = 'x.fmt'
	)
AS
SET NOCOUNT ON
declare @sql nvarchar(max)

declare @open_fn nvarchar(512)
set @sql = 'SELECT * FROM OPENROWSET(''Microsoft.Jet.OLEDB.4.0'',''Text;Database=';
set @sql = @sql + @dbDir;
--if @cols = '*'
--	set @sql = @sql + ';HDR=NO'',''SELECT * FROM [';
--else
--	set @sql = @sql + ';HDR=YES'',''SELECT ' + @cols + ' FROM [';

--set @sql = @sql + @filename + '] where ';
--set @sql = @sql + @whereclause + ''')';

if @cols = '*'
  set @sql = 'SELECT a.* FROM OPENROWSET( BULK ''' + @dbdir + '\' + @filename + ''',FORMATFILE = ''' + @dbdir + '\' + @fmtfile + '''' + ') AS a '
else
  set @sql = 'SELECT ' + @cols + ' FROM OPENROWSET( BULK ''' + @dbdir + '\' + @filename + ''',FORMATFILE = ''' + @dbdir + '\' + @fmtfile + '''' + ') AS a '

/*
set @sql = @sql + @filename + '] ';
set @sql = @sql + ''')';
*/
BEGIN TRY
	--set @sql = 'select * from EXCEL...Main$'
	exec sp_executesql @sql
END TRY
BEGIN CATCH
    -- Execute error retrieval routine.
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH;
RETURN







