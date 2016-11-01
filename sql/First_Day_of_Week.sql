

--select db_dt,datename(week, db_dt) as WK, DATEpart(WEEKDAY,db_dt) as WKDAY, DATENAME(WEEKDAY,db_dt) as DAYName
--from tbl_Prices 
--where db_ticker_id=442
--group by datename(week, db_dt), db_dt
--order by db_dt
set nocount on;
declare @tbl table (db_dt datetime, wk int, wkday int, dayName varchar(20))

declare @start_dt datetime
set @start_dt = '12-31-2000'

declare @cnt int
select @cnt=COUNT(*) from tbl_Prices 
where db_ticker_id=442

declare @idx int
set @idx=1
declare @wk int, @prev_wk int
declare @dt datetime
set @prev_wk=0
while @idx <= @cnt
	begin
		select top 1 @dt=db_dt, @wk=datename(week, db_dt)
		from tbl_Prices 
		where db_ticker_id=442
		and db_dt > @start_dt
		
		set @start_dt = @dt
		if @wk <> @prev_wk
			begin
				set @prev_wk = @wk
				insert @tbl
				select @dt, @wk,DATEpart(WEEKDAY,@dt) as WKDAY, DATENAME(WEEKDAY,@dt) as DAYName
			end
		set @idx=@idx+1
	end
	
	select * from @tbl