alter procedure csp_Calc_Five_Num
(
	@i_dt datetime=null,
	@tick varchar(10),
	@o_min dec(9,2) output,
	@o_hl dec(9,2) output,
	@o_median dec(9,2) output,
	@o_hu dec(9,2) output,	
	@o_max dec(9,2) output,
	@o_price dec(9,2) output

)
as
set nocount on;
/*
USE [IDToDSN_DKC]
GO

DECLARE	@o_min decimal(9, 2),
		@o_hl decimal(9, 2),
		@o_median decimal(9, 2),
		@o_hu decimal(9, 2),
		@o_max decimal(9, 2),
		@o_price dec(9,2)

EXEC	[dbo].[csp_Calc_Five_Num]
		@i_dt = '1-3-2007',
		@tick = N'VEU',
		@o_min = @o_min OUTPUT,
		@o_hl = @o_hl OUTPUT,
		@o_median = @o_median OUTPUT,
		@o_hu = @o_hu OUTPUT,
		@o_max = @o_max OUTPUT,
		@o_price = @o_price OUTPUT

SELECT	@o_min as N'@o_min',
		@o_hl as N'@o_hl',
		@o_median as N'@o_median',
		@o_hu as N'@o_hu',
		@o_max as N'@o_max',
		@o_price as N'@o_price'


*/
declare @today datetime
set @today = @i_dt

declare @ticker_id int
select @ticker_id = db_ticker_id from tbl_Ticker where db_strTicker=@tick

declare @start_dt datetime

set @start_dt = DATEADD(d,-365,@today)
--print @start_dt
--select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @start_dt
if not exists (select * from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @today)
	begin
	select @o_min=0,
		@o_hl=0,
		@o_median=0, 
		@o_hu=0,
		@o_max=0,
		@o_price=0
	return		
	end

declare @MIN dec(9,2), @HL dec(9,2), @MEDIAN dec(9,2), @HU dec(9,2),@MAX dec(9,2)

select @MIN=MIN(db_close), @MAX=MAX(db_close)
from tbl_Prices 
where db_ticker_id = @ticker_id 
and db_dt between @start_dt and @today 

select
    @HL=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount/4+1, (x.TickerCount+1)/4)    
group by
    x.db_ticker_id 

select
    @MEDIAN=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount/2+1, (x.TickerCount+1)/2)    
group by
    x.db_ticker_id 

select
    @HU=AVG(db_close)
from 
(
    select db_ticker_id, db_close, 
        ROW_NUMBER() over (partition by db_ticker_id order by db_close ASC) as CloseRank,
        COUNT(*) over (partition by db_ticker_id) as TickerCount
    from
        tbl_Prices
        where db_ticker_id = @ticker_id 
		and db_dt between @start_dt and @today 
) x
where
    x.CloseRank  in (x.TickerCount*3/4+1, (x.TickerCount+1)*3/4)    
group by
    x.db_ticker_id 

--select @today as Dte, @MIN as MinClose, @HL as HL, @MEDIAN as MedianClose, @HU as HU, @MAX as MaxClose
select @o_min=@MIN,
	@o_hl=@HL,
	@o_median=@MEDIAN, 
	@o_hu=@HU,
	@o_max=@MAX
select	@o_price = db_close from tbl_Prices where db_ticker_id = @ticker_id and db_dt = @i_dt 
--print convert(varchar, @ticker_id) + '--- =' + convert(varchar,@o_price)
