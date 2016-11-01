use IDToDSN_DKC
go

alter procedure csp_Calc_Avg
(
	@s_date datetime,
	@e_date datetime
)
as
set nocount on
-- Step 2.1 and 2.2
declare @ticker_id int
declare @sp_close money
declare @start_date datetime
if @s_date is null
	select @start_date = dateadd(dd, -10, max(db_dt)) from tbl_Prices where db_ticker_id = 538
else
	set @start_date = @s_date

--print @start_date

declare @end_date datetime
if @e_date is null
	select @end_date = max(db_dt) from tbl_Prices where (db_avg <= 0.0 or db_index <= 0.0 or db_mult <= 0.0 or db_avg is null or db_index is null or db_mult is null)
else
	set @end_date = @e_date
--print @end_date

if @end_date is not null
begin
	declare cDSS cursor for
	select db_ticker_id
	from tbl_Ticker
	where db_ticker_id > 0
	order by db_ticker_id

	Open cDSS
	Fetch next from cDSS
	into @ticker_id

	declare @dt1 datetime
	declare @dt2 datetime
	declare @row_id int
	declare @avg float

	while @@FETCH_STATUS = 0
	begin

		select top 1 @row_id = db_row_id, @dt1 = db_dt
		from tbl_Prices
		where db_ticker_id = @ticker_id		
		and db_dt > @start_date
		order by db_dt desc

		set @dt2 = dateadd(dd, -1830, @dt1)
		if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

		select @avg = convert(dec(9,2), avg(db_mult))
		from tbl_Prices
		where db_ticker_id = @ticker_id
		and db_dt between @dt2 and @dt1

		update tbl_Prices
		set db_avg = @avg,
			db_index = convert(dec(9,2), db_close/@avg) * 100.00
		where db_ticker_id = @ticker_id
		and db_dt = @dt1
		and db_row_id = @row_id

		--print convert(varchar,@dt1) + ', ' + convert(varchar, @dt2)

		while exists (select db_dt from tbl_Prices where db_ticker_id = @ticker_id  and (db_avg <= 0.0 or db_index <= 0.0 or db_mult <= 0.0 or db_avg is null or db_index is null or db_mult is null))
		  begin
			select top 1 @dt1 = db_dt, @row_id=db_row_id
			from tbl_Prices
			where db_ticker_id = @ticker_id
			and db_dt < @dt1
			order by db_dt desc


			set @dt2 = dateadd(dd, -1830, @dt1)
			if @dt2 < '1-02-2001' set @dt2 = '1-02-2001'

			--print convert(varchar,@dt1) + ', ' + convert(varchar, @dt2)

			select @avg = convert(dec(9,2), avg(db_mult))
			from tbl_Prices
			where db_ticker_id = @ticker_id
			and db_dt between @dt2 and @dt1

			update tbl_Prices
			set db_avg = @avg,
				db_index = convert(dec(9,2), db_close/@avg) * 100.00
			where db_ticker_id = @ticker_id
			and db_dt = @dt1
			and db_row_id = @row_id

			print 'row id=' + convert(varchar, @row_id) + ', ' + 'ticker id=' + convert(varchar, @ticker_id) + ', ' + 'avg=' + convert(varchar, @avg)


		  end

		Fetch next from cDSS
		into @ticker_id

	end
	close cDSS
	Deallocate cDSS
end
else
	print 'no end date'