set nocount on;
declare @tid int

select @tid = db_ticker_id  from tbl_Ticker
where db_strTicker = 'twtc'

declare @tbl table (idx int identity, dt datetime, mult dec(9,2), tkn int)
declare @tbl_DB table (idx int, dt datetime, mult dec(9,2), tkn int)

insert @tbl
select db_dt, convert(dec(9,2),db_mult),0 from tbl_Prices
where db_ticker_id = @tid
and db_dt > '8-1-2013'
group by db_dt, db_mult
order by db_dt, db_mult 

declare @cnt int
select @cnt=COUNT(*) from @tbl

declare @idx int
set @idx=1

declare @t_prev_idx int
declare @t_prev_dt datetime
declare @t_prev_mult dec(9,2)
declare @t_idx int
declare @t_dt datetime
declare @t_mult dec(9,2)

--select @t_prev_idx=@idx, @t_prev_dt = dt, @t_prev_mult = mult from @tbl where idx = @idx
--set @idx=@idx+1
declare @tkn int
set @tkn=1
while @idx < @cnt
begin
	select @t_idx=idx, @t_dt = dt, @t_mult = mult from @tbl where idx = @idx
	if exists (select * from @tbl where mult = @t_mult and idx < @t_idx and MONTH(dt) < MONTH(@t_dt))
	  begin
		select @t_prev_idx=idx, @t_prev_dt = dt, @t_prev_mult = mult from @tbl 
		where (mult between @t_mult-.05 and @t_mult+.05) and idx < @t_idx and MONTH(dt) < MONTH(@t_dt)
		
	  
		insert @tbl_DB
		select top 5 idx, dt, mult, @tkn from @tbl
		where (mult between @t_mult-.05 and @t_mult+.05) and idx < @t_idx and MONTH(dt) < MONTH(@t_dt)
		order by idx asc
		
		insert @tbl_DB
		select @t_idx, @t_dt, @t_mult, @tkn
		set @tkn = @tkn + 1
	  end
	set @idx=@idx+1
end
select * from @tbl
select * from @tbl_DB
select tkn, COUNT(*) from @tbl_DB group by tkn
