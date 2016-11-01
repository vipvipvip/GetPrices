declare @tbl table (idx int identity, tid int, dt datetime)

insert @tbl
select P.db_ticker_id, P.db_dt 
from tbl_Prices P, tbl_Return_Rank R
where  P.db_ticker_id = R.tid
and P.db_dt = R.dt
and db_type in (1,2,3)
--and db_slope is null
and db_dt > '12-30-2006'
order by db_dt, R.strTicker

declare @id int
set @id=1
declare @t int, @sd datetime

while exists (select * from @tbl where idx = @id)
 begin
	select @t=tid,  @ed = dateadd(y, -1, dt) from @tbl where idx =@id

	EXECUTE [csp_Calc_Update_Slope_2]
	@s_date=@sd, @e_date='4-1-2015', @typ=-1, @tick_id=@t

	set @id=@id+1
 end

select  R.strTicker, P.*
from tbl_Prices P, tbl_Return_Rank R
where  P.db_ticker_id = R.tid
and P.db_dt = R.dt
--and db_type = 3
and db_slope is null
and db_dt > '12-30-2006'
order by db_dt, R.strTicker
