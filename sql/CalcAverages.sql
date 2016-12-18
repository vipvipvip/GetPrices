alter procedure [dbo].[csp_Calc_Averages]
(
	@s_date datetime  = '1-1-2016',
	@typ smallint = 2,
	@tick_id int=0,
	@strTick varchar(10)=null
)
as

declare @tbl table (idx int identity(1,1), tickID int)
declare @tid int

if @strTick is not null
	insert @tbl
	select db_ticker_id from tbl_Ticker where db_strTicker = @strTick
else if @tick_id > 0
	insert @tbl
	select @tick_id
else if (@typ > 0)
	insert @tbl
	select db_ticker_id from tbl_Ticker where db_type = @typ

if @@ROWCOUNT <= 0 return;

declare @idx int
set @idx = 1
while exists (select * from @tbl where idx = @idx)
  begin

	select @tid = tickID from @tbl where idx = @idx
	print 'Processing ' + convert(varchar, @tid)

	update tbl_Prices
	set db_MA50 = A.MA50
	from (
	select t.db_dt as DT, round(t.db_close,2) as db_close,
			round((case when row_number() over (order by db_dt) >= 50
					then avg(db_close) over (order by db_dt rows between 49 preceding and current row)
					else 0
			end),2) as MA50
	from tbl_Prices t
	where t.db_ticker_id = @tid
	and t.db_dt >= @s_date
	) as A
	where db_ticker_id = @tid
	and db_dt = A.DT

	update tbl_Prices
	set db_MA200 = A.MA200
	from (
	select t.db_dt as DT, round(t.db_close,2) as db_close,
			round((case when row_number() over (order by db_dt) >= 200
					then avg(db_close) over (order by db_dt rows between 199 preceding and current row)
					else 0
			end),2) as MA200
	from tbl_Prices t
	where db_ticker_id = @tid
	and t.db_dt >= @s_date
	) as A
	where db_ticker_id = @tid
	and db_dt = A.DT

	exec dbo.csp_Calc_EMA @s_date = @s_date, @tid = @tid

	set @idx = @idx+1
  end
