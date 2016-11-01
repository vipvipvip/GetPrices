declare @dir varchar(50)
set @dir = 'c:\stockmon'

declare @srcFN varchar (100)
--set @srcFN = 'nasdaq100.csv'
set @srcFN = 'vg_etf.csv'
--set @srcFN = NULL
--set @srcFN = 'TLT, DD, ISRG, WMT, MA,VIS,VNQ, WFM, AAL'

declare @today datetime
set @today = '7-10-2015'

declare @tbl table (idx int identity, fn varchar(100) )
if @srcFN is not null
  begin
	declare @tbl_Current table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), vix dec(9,2), rRank int)
	if PATINDEX('%csv%', @srcFN) <= 0
		insert @tbl
		select LTRIM(RTRIM(val)) from [fn_SplitToTable]( @srcFN, ',')
	else
		insert @tbl
		EXEC	[dbo].[csp_ReadCSV]
				@filename = @srcFN,
				@dbDir = @dir,
				@cols='Ticker',
				@whereclause = N'1=1'
  end
else
  begin
	IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
		 DROP TABLE #DirectoryTree;

	CREATE TABLE #DirectoryTree (
		   id int IDENTITY(1,1)
		  ,subdirectory nvarchar(512)
		  ,depth int
		  ,isfile bit);

	insert #DirectoryTree
	exec sp_getfilenames @dir

	insert @tbl
	select subdirectory from #DirectoryTree
	where subdirectory like '%.csv'

	DROP TABLE #DirectoryTree;
  end 	

declare @id int
set @id=1

declare @fn varchar(100)


while exists (select * from @tbl where idx = @id)
  begin
	select @fn = fn from @tbl where idx = @id
	if @srcFN is null
		EXECUTE [csp_Calc_Ret_From_CSV] null, null, @fn, @dir
	else
		insert @tbl_Current
		EXECUTE csp_Calc_Ret_Using_Lag 
		   @sdt=@today
		  ,@tick=@fn
	set @id = @id + 1
  end


if @srcFN is not null
  begin
	declare @sum dec(9,3)
	select @sum = SUM(rRank) from @tbl_Current 
	declare @port dec(9,3)
	set @port = 70000.00

	select *
		, CONVERT(int, rRank/@sum*100) as [%Alloc]
		, CONVERT(int, rRank/@sum * @port) as [$Amt] 
		, CONVERT(int, rRank/@sum * @port / price ) as [Shares]
	from @tbl_Current
	where rRank > 0
	order by rRank desc
  end