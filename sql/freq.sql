/*
alter procedure csp_Calc_Freq_For_Strategy_Tickers
(
	@dt smalldatetime = null
)
as
--EXECUTE [IDToDSN_DKC].[dbo].[csp_Calc_Freq_For_Strategy_Tickers]

begin
declare @tbl table (id int identity, ticker varchar(10), freq_rank int null)
insert @tbl select
'VTI', 0 insert @tbl select
'VEU', 0 insert @tbl select
'VNQ', 0 insert @tbl select
'TIP', 0 insert @tbl select
'TLT', 0 insert @tbl select
'IVV', 0 insert @tbl select
'VO', 0 insert @tbl select
'VB', 0 insert @tbl select
'ACWX', 0 insert @tbl select
'IYR', 0 insert @tbl select
'AGG', 0 insert @tbl select
'VCR', 0 insert @tbl select
'VDC', 0 insert @tbl select
'VDE', 0 insert @tbl select
'VFH', 0 insert @tbl select
'VHT', 0 insert @tbl select
'VIS', 0 insert @tbl select
'VAW', 0 insert @tbl select
'VGT', 0 insert @tbl select
'VPU', 0 insert @tbl select
'IWV', 0 insert @tbl select
'IJK', 0 insert @tbl select
'IJT', 0 insert @tbl select
'EEM', 0 insert @tbl select
'LQD', 0

declare @cnt int
select @cnt = COUNT(*) from @tbl
declare @id int
set @id=1
declare @tick varchar(10)
declare @freq_rank int
declare @price dec(9,2)

while @id <= @cnt
  begin
	select @tick = ticker from @tbl where id=@id
	exec @freq_rank = csp_Calc_Freq_Rank @dt, null, @tick, @ret_price = @price OUTPUT

	update @tbl
	set freq_rank = @freq_rank
	where id = @id
	
	set @id = @id+1
  end
  
  select * from @tbl
  
 end
*/
 
/*
alter procedure csp_Calc_Freq_Monthly
(
	@sdt smalldatetime = null,
	@tick varchar(10) = null
)
as
begin

	--input parm
	declare @start_dt smalldatetime
	declare @strTick varchar(10)
	if @tick is not null set @strTick = @tick 
	if @sdt is null set @start_dt = '1-1-2007' else set @start_dt = @sdt

	declare @tid int
	declare @strTicker varchar(50)

	if @strTick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_type=2
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @strTick
		order by db_ticker_id

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @s_yr int
			set @s_yr = YEAR(@start_dt)

			declare @e_yr int
			set @e_yr = year(GETDATE())
			print @e_yr

			declare @iMonth int
			set @iMonth = 1
			declare @dt varchar(10)
			declare @freq_rank int
			declare @price dec(9,2)
			while @s_yr <= @e_yr
			  begin
			  --print '= ' + convert(varchar, @s_yr)
				while ( @s_yr=@e_yr and @iMonth <= month(GetDate()) ) or ( @s_yr<@e_yr and @iMonth <= 12)
				  begin
					--print '===== ' + convert(varchar, @iMonth)
					set @dt = convert(varchar, @iMonth) + '-1-' +  convert(varchar, @s_yr)
					print @dt
					exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT

					if @price is null set @price = 0
					delete tbl_Freq_Rank
					where db_ticker_id = @tid and db_dt = @dt
					
					insert tbl_Freq_Rank
					select @tid,  @dt, @freq_rank, @price

					set @iMonth = @iMonth+1
				  end
				set @s_yr = @s_yr+1
				set @iMonth = 1
			  end

			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS
		  
	END TRY

	BEGIN CATCH
	close cDSS
	Deallocate cDSS

		-- Execute error retrieval routine.
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT 
			@ErrorMessage = ERROR_MESSAGE() + ', ' + convert(varchar, @dt),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH;
end
*/
/*
alter procedure csp_Calc_Freq_Rank_For_ALL_ETF
(
	@dt smalldatetime = null,
	@tick varchar(10) = null
)		
as
begin

	if @dt is null set @dt = GETDATE()
	declare @strTicker varchar(50)
	declare @tid int

	if @tick is null
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_type=2
		order by db_ticker_id
	else
		declare cDSS scroll cursor for
		select db_ticker_id, db_strTicker
		from tbl_Ticker
		where db_strTicker = @tick
		order by db_ticker_id
	declare @tbl TABLE (id int identity(1,1), Ticker varchar(10), dt smalldatetime, freq_rank int, price dec(9,2) )

	BEGIN TRY

		Open cDSS
		Fetch next from cDSS
		into @tid, @strTicker

		while @@FETCH_STATUS = 0
		begin
			declare @freq_rank int
			declare @price dec(9,2)
			exec @freq_rank = csp_Calc_Freq_Rank @dt, @tid, null, @ret_price = @price OUTPUT

			insert @tbl
			select @strTicker, @dt, @freq_rank, @price
			
			Fetch next from cDSS
			into @tid, @strTicker
		end
	close cDSS
	Deallocate cDSS

	select * from @tbl order by Ticker
		  
	END TRY

	BEGIN CATCH
	close cDSS
	Deallocate cDSS

		-- Execute error retrieval routine.
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT 
			@ErrorMessage = ERROR_MESSAGE() + ', ' + convert(varchar, @dt),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH;

end
*/

/*
alter procedure csp_Calc_Freq_Rank
(
	@dt datetime=null,
	@ticker_id int=null,
	@str_ticker varchar(10)=null,
	@ret_price dec(9,2) output
)
as
begin

set nocount on;
--input date & ticker ID to this procedure
declare @today datetime
if @dt is null
	set @today = GETDATE()
else
	set @today = @dt
	
declare @aid int
if @ticker_id is null
	if @str_ticker is not null
		select @aid = db_ticker_id from tbl_Ticker where db_strTicker = @str_ticker
	else
		return 0
else
	set @aid = @ticker_id


declare @spid int
declare @spidx dec(9,2)
declare @price dec(9,2)
set @spid = 538

declare @start datetime
set @start = dateadd(yy, -5, @today)
print @start


declare @tbl TABLE (id int Identity(1,1), db_dt datetime, mplr dec(9,2), price dec(9,2), sp_idx dec(9,2), mplr_minus_sd dec(9,2) null, mplr_mean dec(9,2) null, mplr_plus_sd dec(9,2) null, price_minus_sd dec(9,2) null, price_mean dec(9,2) null, price_plus_sd dec(9,2) null  )

insert @tbl
select A.db_dt, convert(dec(9,2), A.db_close/B.db_close*100), A.db_close, B.db_close,0,0,0,0,0,0
from tbl_Prices A, tbl_Prices B
where A.db_dt = B.db_dt
and B.db_ticker_id = @spid
and A.db_ticker_id = @aid
and A.db_dt >= @start
and A.db_dt <= @today

declare @min_mplr dec(9,2)
declare @max_mplr dec(9,2)
declare @sd_mplr dec(9,2)
declare @avg_mplr dec(9,2)

select @avg_mplr=avg(mplr), @min_mplr=MIN(mplr), @max_mplr=Max(mplr), @sd_mplr=stdev(mplr) from @tbl

declare @t_mplr dec(9,2)
declare @t_mplr_mean dec(9,2)
declare @t_mplr_stdev dec(9,2)

declare @t_price dec(9,2)
declare @t_price_mean dec(9,2)
declare @t_price_stdev dec(9,2)

declare @id_start int
set @id_start = 1

declare @idx int
set @idx=27
while exists (select * from @tbl where id = @idx)
  begin
	select @t_mplr = mplr, @t_mplr = price from @tbl where id = @idx
	
	select @t_mplr_mean = AVG(mplr), @t_mplr_stdev = stdev(mplr),
	@t_price_mean = AVG(price), @t_price_stdev = stdev(price)
	from @tbl where id between @id_start and @idx
	
	update @tbl 
	set mplr_mean=@t_mplr_mean, 
		mplr_minus_sd=@t_mplr_mean-@t_mplr_stdev, 
		mplr_plus_sd=@t_mplr_mean+@t_mplr_stdev,
		price_mean=@t_price_mean, 
		price_minus_sd=@t_price_mean-@t_price_stdev, 
		price_plus_sd=@t_price_mean+@t_price_stdev 		 
	where id = @idx
	
	set @idx=@idx+1
	set @id_start = @id_start+1
  end
  
-- update first 26 rows.
update @tbl
set mplr_mean = A.mplr_mean,
mplr_minus_sd = A.mplr_minus_sd,
mplr_plus_sd  = A.mplr_plus_sd,
price_mean    = A.price_mean,
price_minus_sd  = A.price_minus_sd,
price_plus_sd = A.price_plus_sd
from (select mplr_mean, mplr_minus_sd, mplr_plus_sd, price_mean, price_minus_sd, price_plus_sd from @tbl where id = 27) as A
where id <= 26

 select @spidx=sp_idx, @price=price  from @tbl where id = @idx-1  
 --select * from @tbl
 --select @avg_mplr as avg_mplr, @min_mplr as min_mplr, @max_mplr as max_mplr, @sd_mplr as sd_mplr, @spidx as SPINDEX, @price as PRICE
  
 -- ***************** Begin freq table { **************** 
 declare @tbl_freq table (id int identity(1,1), freq int null, mult dec(9,2) null, price dec(9,2) null)
 -- prime the table
 insert @tbl_freq
 select 0, 0, 0
 from @tbl
 where id <= 26
 
 update @tbl_freq
 set mult = @min_mplr
 where id=1
 
 update @tbl_freq
 set mult = @max_mplr
 where id=26

 update @tbl_freq
 set mult = (@min_mplr+@max_mplr)/2
 where id=14
 
 declare @t_mult dec(9,2)
 set @t_mult = @min_mplr
 set @idx=2
 while @idx<= 13
   begin
	set @t_mult = @t_mult  + (@avg_mplr - @min_mplr)/13
    update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 update @tbl_freq 
 set mult = @avg_mplr where id=@idx
 set @idx=15
 set @t_mult = @avg_mplr
 while @idx < 26
   begin
	set @t_mult = @t_mult  + (@max_mplr - @avg_mplr)/13
	update @tbl_freq 
    set mult =  @t_mult where id=@idx
	set @idx=@idx+1
   end
 
 --set price
 update @tbl_freq
 set price = mult *  @spidx / 100
 
 --update freq
 declare @cnt int
 select @cnt = COUNT(*) from @tbl where mplr <= @min_mplr 
 update @tbl_freq 
 set freq = @cnt
 where id=1
 
 declare @curr_mult dec(9,2)
 declare @prev_mult dec(9,2)
 set @idx=2
 while @idx <= 26
   begin
	select @curr_mult = mult from @tbl_freq where id = @idx
	select @prev_mult = mult from @tbl_freq where id = @idx-1
	
	update @tbl_freq 
	set freq = A.CNT_ITEMS
	from ( select COUNT(*) as CNT_ITEMS from @tbl where mplr  between @prev_mult and @curr_mult) as A
	where id = @idx
	
	set @idx=@idx+1
   end
-- select * from @tbl_freq
-- ***************** end freq table } **************** 

declare @ac_38 dec(9,2), @ac_39 dec(9,2), @ac_40 dec(9,2)
declare @ad_39 dec(9,2)

select @ad_39 = MAX(price_mean) from @tbl where id > 26
set @ac_38 = @spidx * @avg_mplr / 100

select @ac_39 = AVG(price) 
from @tbl_freq 
where price > 0 and freq > 11

select @ac_40 = price
from @tbl_freq 
where freq = (select MAX(freq) from @tbl_freq)

declare @af_35 dec(9,2)
declare @ah_35 dec(9,2)

declare @af_36 dec(9,2)
declare @ah_36 dec(9,2)

declare @af_37 dec(9,2)
declare @ah_37 dec(9,2)


if (@ac_38+@ac_39+@ac_40)/3 < @ad_39 
	set @af_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @af_35 = @ad_39

if (@ac_38+@ac_39+@ac_40)/3 > @ad_39 
	set @ah_35 = (@ac_38+@ac_39+@ac_40)/3
else
	set @ah_35 = @ad_39

set @af_36 = @spidx * (@avg_mplr-@sd_mplr) / 100
set @ah_36 = @spidx * (@avg_mplr+@sd_mplr) / 100

set @af_37 = @spidx * @min_mplr  / 100
set @ah_37 = @spidx * @max_mplr  / 100

/*
select @ac_38 as AC38, @ac_39 as AC39, @ac_40 as AC40, @ad_39 as AD39
select @af_35  as AF35, @ah_35 as AH35
select @af_36 as AF36, @ah_36 as AH36 
select @af_37 as AF37, @ah_37 as AH37 
*/
-- final table
declare @af_38 dec(9,2)
declare @ah_38 dec(9,2)

declare @af_39 dec(9,2)
declare @ah_39 dec(9,2)

declare @ag_39 dec(9,2)

declare @af_40 dec(9,2)
declare @ah_40 dec(9,2)

set @af_38 = (@af_35 + @af_36 + @af_37 ) /3
set @ah_38 = (@ah_35 + @ah_36 + @ah_37 ) /3

set @af_40 = (@ah_38 - @af_38)/4 + @af_38


set @af_39 = (@af_38 + @af_40) /2
set @ag_39 = (@af_38 + @ah_38) / 2

set @ah_40 = 3*((@ah_38 - @af_38)/4) + @af_38
set @ah_39 = (@ah_38 + @ah_40) /2

/*
select @af_38 as AF38, 0 as XX38, @ah_38 as AH38
select @af_39 as AF38, @ag_39 as AG39, @ah_39 as AH39
select @af_40 as AF40, 0 as XX40, @ah_40 as AH40
*/
declare @freq_rank int

select @freq_rank= case
	when @price > @ah_38 then 7
	when @price > @ah_39 then 6
	when @price > @ah_40 then 5
	when @price > @ag_39 then 4
	when @price > @af_40 then 3
	when @price > @af_39 then 2
	when @price > @af_38 then 1
	else 0
	end

set @ret_price = @price
return @freq_rank


end
*/