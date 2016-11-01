DECLARE @RC int
DECLARE @dt datetime
DECLARE @ticker_id int
DECLARE @ret_price decimal(9,2)
declare @wk int
declare @prev_wk int
declare @str_ticker varchar(10)

declare @tbl table (idx int identity, tid int, wkDt datetime)

--select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker, datepart(dw,db_dt)
--	from tbl_Ticker T, tbl_Prices P
--	where db_dt >= '12-31-2005'
--	and T.db_ticker_id = P.db_ticker_id 
--	and T.db_inactive_dt is null
--	and (T.db_strTicker = 'SPY')


declare cDSSSW scroll cursor for
select T.db_ticker_id, db_dt, datepart(wk,db_dt),T.db_strTicker
	from tbl_Ticker T, tbl_Prices P
	where db_dt >= '12-31-2005'
	and T.db_ticker_id = P.db_ticker_id 
	and T.db_inactive_dt is null
	and (T.db_strTicker = 'SPY')
	and datepart(dw,db_dt) <= 3


Open cDSSSW
Fetch next from cDSSSW
into @ticker_id, @dt, @wk, @str_ticker
set @prev_wk = 0

while @@FETCH_STATUS = 0
begin
	if @wk > @prev_wk or @prev_wk - @wk >= 51
	begin
		insert @tbl
		select @ticker_id, @dt
	end

	set @prev_wk = @wk
	Fetch next from cDSSSW
	into @ticker_id, @dt, @wk, @str_ticker

end
close cDSSSW
Deallocate cDSSSW

select P.db_ticker_id, P.db_dt, P.db_close
from @tbl X, tbl_Prices P
where X.tid = P.db_ticker_id
and X.wkDt = P.db_dt