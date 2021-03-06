/*
declare @syr int
set @syr = 2001

declare @sMth int
set @sMth = 1

declare @tbl table (idx int identity, price_dt varchar(12), freq_dt varchar(12))

declare @dt1 varchar(12)
declare @dt2 varchar(12)
while @syr < 2012
 begin

	while @sMth < 12
	begin
		select @dt1=MIN(db_dt) from tbl_Prices where db_ticker_id = 538
		and YEAR(db_dt) = @syr and MONTH(db_dt)= @sMth
		
		select @dt2=MIN(db_dt) from tbl_Freq_Rank 
		where YEAR(db_dt) = @syr and MONTH(db_dt)= @sMth
		
		if @dt2 is not null and @dt1 <> @dt2
		begin
			update tbl_Freq_Rank
			set db_dt = @dt1
			where db_dt = @dt2
		end
		insert @tbl
		select @dt1, @dt2

		set @sMth = @sMth + 1
	end	
	set @syr = @syr + 1
	set @sMth = 1
 end
  
select * from @tbl where freq_dt is not null and price_dt <> freq_dt 
*/
/*
update tbl_Freq_Rank 
set db_close = CLS
from (select db_ticker_id TID, db_dt DTE, db_close CLS from tbl_Prices) as A
where TID = db_ticker_id
and DTE = db_dt 

update tbl_FiveNum 
set db_close = CLS
from (select db_ticker_id TID, db_dt DTE, db_close CLS from tbl_Prices) as A
where TID = db_ticker_id
and DTE = db_dt 
*/

select * from tbl_Freq_Rank where db_ticker_id = 471