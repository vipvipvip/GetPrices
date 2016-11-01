-- This script is same as ProcessCSV.sql except that 
-- when srcFN is null (meaning reading CSV files of tickers )
-- it combines all the tickers and runs them as if they were 
-- in the same file
-- So instead of seeing multiple selects for each CSV, 
-- the output is one combined table with tickers 
-- from all the CSVs processed.
declare @dir varchar(50)
set @dir = 'c:\stockmon'

declare @rRankMultiple int
set @rRankMultiple = 1

declare @srcFN varchar (100)
set @srcFN = 'TAA_Funds.csv' -- 'SPYTickers.csv' -- 'picks.csv'
set @srcFN = NULL
--set @srcFN = 'TLT, DD, ISRG, WMT, MA,VIS,VNQ, WFM, AAL'

declare @today datetime
set @today = '1-1-2007' --GETDATE()

declare @tbl table (idx int identity, fn varchar(100) )
declare @tbl_Final table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), rRank int)

if @srcFN is not null
  begin
	declare @tbl_Current table (tid int, strTicker varchar(10), dt datetime, 
					price dec(9,2), r1 dec(9,2),r3 dec(9,2),r6 dec(9,2), r12 dec(9,2), rRank int)
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
		begin
		-- process csv files
		declare @tblTick table (idx int identity, Ticks varchar(100) )

		insert @tblTick
		EXEC	[dbo].[csp_ReadCSV]
		@filename = @fn,
		@dbDir = @dir,
		@cols='Ticker',
		@whereclause = N'1=1'

		delete from @tblTick where Ticks  like '%.%'
		delete from @tblTick where Ticks like '%--%'
		delete from @tblTick where Ticks like '%/%'
		insert @tbl_Current
		EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Ret] 
		   @sdt=@today
		  ,@tick=@fn

		--exec [IDToDSN_DKC].[dbo].[csp_Calc_Ret_From_CSV] @Curr_dt=null, @Prev_dt=null, @fn= @fn, @dir=@dir 
		end
	else
		insert @tbl_Current
		EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Ret] 
		   @sdt=@today
		  ,@tick=@fn

	set @id = @id + 1
  end

set @id=1
if @srcFN is null
  begin
	while exists (select * from @tblTick where idx = @id)
		begin
			select @fn = Ticks from @tblTick where idx = @id
			insert @tbl_Current
			EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Ret] 
			   @sdt=@today
			  ,@tick=@fn
			
			set @id=@id+1
		end
  end

-- get rid of dupe tickers
insert @tbl_Final 
select distinct * from @tbl_Current where rRank is not null order by strTicker

--if @srcFN is not null
  begin
	declare @MEDIAN dec(9,3)
------
select
    @MEDIAN=AVG(rRank)
from 
(
    select distinct tid, rRank, 
        ROW_NUMBER() over (partition by tid order by rRank ASC) as CloseRank,
        COUNT(*) over (partition by tid) as TickerCount
    from
        @tbl_Final
    where rRank >= 10
) x
where
    x.CloseRank  in (x.TickerCount/2+1, (x.TickerCount+1)/2)
    and x.rRank >= 10  
group by
    x.tid 


------

	declare @sum dec(9,3)
	select @sum = SUM(rRank) from @tbl_Final where rRank >=  @rRankMultiple * @MEDIAN
	declare @port dec(9,3)
	set @port = 70000.00

	select *
		, CONVERT(dec(9,3), rRank/@sum*100) as [%Alloc]
		, CONVERT(int, rRank/@sum * @port) as [$Amt] 
		, CONVERT(int, rRank/@sum * @port / price ) as [Shares]
	from @tbl_Final
	where rRank >= @rRankMultiple * @MEDIAN
	order by rRank desc
  end