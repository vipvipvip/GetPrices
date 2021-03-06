SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_Add]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Ticker_Add]
(
		@db_scrip_cd int = NULL, 
		@db_scrip_name varchar(50)=NULL,

	@retval int output		-- row id
) 
As
	declare @cols nvarchar(1024), @val nvarchar(1024)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''
	set @val = '' values (''
	declare @sql nvarchar(4000)

	set @sql = ''insert into dbo.tbl_BSE_Ticker'' + '' '' +  '' (db_scrip_cd, db_scrip_name) ''
	set @sql = @sql + '' values ( ''
	
if ( @db_scrip_cd is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_scrip_cd'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_scrip_name is not NULL)
	   BEGIN
			set @sql = @sql +   @Comma + '' @db_scrip_name '' 
			set @Comma = N'',''
	   END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 



	set @sql = @sql + '' ) ''

	exec sp_executesql @sql,
	N''@db_scrip_cd int,
@db_scrip_name varchar(50)'',
	@db_scrip_cd,
@db_scrip_name

set @retval=@@IDENTITY
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_Update]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Ticker_Update]
(

		@db_ticker_id int  = NULL, 
		@db_scrip_cd int = NULL, 
		@db_scrip_name varchar(50)=NULL,

	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''

	set @sql = N''update dbo.tbl_BSE_Ticker'' + '' ''  + '' set ''

 if @db_ticker_id is NULL 
    begin 
     	raiserror (''Please provide a key to update a record in tbl_BSE_Ticker.'', 16, 1) 
     	return -101 
    end 
if ( @db_scrip_cd is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_scrip_cd =  @db_scrip_cd ''  
			set @Comma = N'',''
		  END
if ( @db_scrip_name is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_scrip_name = @db_scrip_name '' 
			set @Comma = N'',''
		 END


	set @sql = @sql + N'' where db_ticker_id = '' +  CONVERT(nvarchar, @db_ticker_id)

	exec sp_executesql @sql,
	N''@db_scrip_cd int,
@db_scrip_name varchar(50)'',
	@db_scrip_cd,
@db_scrip_name


	select @retval = @@ROWCOUNT
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_Delete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Ticker_Delete]
(
	@db_ticker_id int=NULL,
	@retval int output		
) 
As
	if @db_ticker_id IS NULL
	begin
		raiserror (''Please provide a key to delete a record in tbl_BSE_Ticker.'', 16, 1)
		return
	end

	

	Declare @sql nvarchar(4000)

	set @sql = N''delete from dbo.tbl_BSE_Ticker'' + '' '' + '' where db_ticker_id = @db_ticker_id ''
	set @sql = @sql + '' '' + '' '' 

	exec @retval = sp_executesql @sql,
	N''@db_ticker_id int '',
	@db_ticker_id

	select @retval = @@ROWCOUNT
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_Delete_Where]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
Create PROCEDURE  [dbo].[csp_tbl_BSE_Ticker_Delete_Where]
(
	@whereclause nvarchar(3000) = NULL,
	@db_Year int=-1,
	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''

	if @whereclause IS NULL
		BEGIN
			set @sql = N''delete from dbo.tbl_BSE_Ticker''
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
		END
	else
		BEGIN
			set @sql = N''delete from dbo.tbl_BSE_Ticker''			
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
			set @sql = @sql + '' where ''			
			set @sql = @sql + @whereclause
		END
	exec sp_executesql @sql
	select @retval = @@ROWCOUNT

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_GetByID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [dbo].[csp_tbl_BSE_Ticker_GetByID]
(
	@db_ticker_id int 
)
as
	if @db_ticker_id IS NULL
	begin
		raiserror (''Please provide a key to query tbl_BSE_Ticker.'', 16, 1)
		return -101
	end

	

	Declare @cmd nvarchar(4000)

	set @cmd = N''select db_ticker_id, db_scrip_cd, db_scrip_name ''
	set @cmd = @cmd + N'' from dbo.tbl_BSE_Ticker'' + '' ''
	set @cmd = @cmd + N'' where db_ticker_id = @db_ticker_id ''
	set @cmd = @cmd + '' ''
	exec sp_executesql @cmd,
	N''@db_ticker_id int '',
	@db_ticker_id

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Ticker_List]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [dbo].[csp_tbl_BSE_Ticker_List]
(
	@cols nvarchar(2000) = NULL,
	
	@whereclause nvarchar(2000) = NULL

)
as
	Declare @sql nvarchar(4000)
	if @cols IS NULL
	BEGIN
	
		if @whereclause IS NULL
			BEGIN
				set @sql = N''select * from dbo.tbl_BSE_Ticker''
			END
		else
			BEGIN
				Set @sql = N''select * from dbo.tbl_BSE_Ticker where '' + @whereclause
			END
	END
	else
	BEGIN
		if @whereclause IS NULL
			BEGIN
				set @sql = N''select  '' + @cols + '' from dbo.tbl_BSE_Ticker''
			END
		else
			BEGIN

				Set @sql = N''select ''
				Set @sql = @sql + @cols
				set @sql = @sql + '' from dbo.tbl_BSE_Ticker where '' + @whereclause
			END
	END
	exec sp_executesql @sql

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_Add]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Prices_Add]
(
		@db_ticker_id int = NULL, 
		@db_volume int = NULL, 
		@db_dt smalldatetime = NULL, 
		@db_close real = NULL, 
		@db_mult real = NULL, 
		@db_avg real = NULL, 
		@db_index real = NULL, 
		@db_rank smallint = NULL, 
		@db_mult_avg_ratio real = NULL, 
		@db_rank_change smallint = NULL, 
		@db_change_rank smallint = NULL, 

	@retval int output		-- row id
) 
As
	declare @cols nvarchar(1024), @val nvarchar(1024)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''
	set @val = '' values (''
	declare @sql nvarchar(4000)

	set @sql = ''insert into dbo.tbl_BSE_Prices'' + '' '' +  '' (db_ticker_id, db_volume, db_dt, db_close, db_mult, db_avg, db_index, db_rank, db_mult_avg_ratio, db_rank_change, db_change_rank) ''
	set @sql = @sql + '' values ( ''
	
if ( @db_ticker_id is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_ticker_id'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_volume is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_volume'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_dt is not NULL)
	   BEGIN
			set @sql = @sql +   @Comma + '' @db_dt '' 
			set @Comma = N'',''
	   END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_close is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_close'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_mult is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_mult'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_avg is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_avg'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_index is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_index'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_rank is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_rank'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_mult_avg_ratio is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_mult_avg_ratio'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_rank_change is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_rank_change'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 

if ( @db_change_rank is not NULL)
  BEGIN
			set @sql = @sql + @Comma + '' @db_change_rank'' 
			set @Comma = N'',''
	END
 else 
   BEGIN 
     set @sql = @sql + @Comma + '' DEFAULT '' 
     set @Comma = N'','' 
   END 



	set @sql = @sql + '' ) ''

	exec sp_executesql @sql,
	N''@db_ticker_id int,
@db_volume int,
@db_dt smalldatetime,
@db_close real,
@db_mult real,
@db_avg real,
@db_index real,
@db_rank smallint,
@db_mult_avg_ratio real,
@db_rank_change smallint,
@db_change_rank smallint'',
	@db_ticker_id,
@db_volume,
@db_dt,
@db_close,
@db_mult,
@db_avg,
@db_index,
@db_rank,
@db_mult_avg_ratio,
@db_rank_change,
@db_change_rank

set @retval=@@IDENTITY
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_Update]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Prices_Update]
(

		@db_row_id int  = NULL, 
		@db_ticker_id int = NULL, 
		@db_volume int = NULL, 
		@db_dt smalldatetime = NULL, 
		@db_close real = NULL, 
		@db_mult real = NULL, 
		@db_avg real = NULL, 
		@db_index real = NULL, 
		@db_rank smallint = NULL, 
		@db_mult_avg_ratio real = NULL, 
		@db_rank_change smallint = NULL, 
		@db_change_rank smallint = NULL, 

	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''

	set @sql = N''update dbo.tbl_BSE_Prices'' + '' ''  + '' set ''

 if @db_row_id is NULL 
    begin 
     	raiserror (''Please provide a key to update a record in tbl_BSE_Prices.'', 16, 1) 
     	return -101 
    end 
if ( @db_ticker_id is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_ticker_id =  @db_ticker_id ''  
			set @Comma = N'',''
		  END
if ( @db_volume is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_volume =  @db_volume ''  
			set @Comma = N'',''
		  END
if ( @db_dt = ''1/1/1900'') 
	   BEGIN
			set @sql = @sql + @Comma + N'' db_dt = NULL '' 
			set @Comma = N'',''
		 END
else
if ( @db_dt is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_dt = @db_dt '' 
			set @Comma = N'',''
		 END
if ( @db_close is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_close =  @db_close ''  
			set @Comma = N'',''
		  END
if ( @db_mult is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_mult =  @db_mult ''  
			set @Comma = N'',''
		  END
if ( @db_avg is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_avg =  @db_avg ''  
			set @Comma = N'',''
		  END
if ( @db_index is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_index =  @db_index ''  
			set @Comma = N'',''
		  END
if ( @db_rank is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_rank =  @db_rank ''  
			set @Comma = N'',''
		  END
if ( @db_mult_avg_ratio is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_mult_avg_ratio =  @db_mult_avg_ratio ''  
			set @Comma = N'',''
		  END
if ( @db_rank_change is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_rank_change =  @db_rank_change ''  
			set @Comma = N'',''
		  END
if ( @db_change_rank is not NULL)
	   BEGIN
			set @sql = @sql + @Comma + N'' db_change_rank =  @db_change_rank ''  
			set @Comma = N'',''
		  END


	set @sql = @sql + N'' where db_row_id = '' +  CONVERT(nvarchar, @db_row_id)

	exec sp_executesql @sql,
	N''@db_ticker_id int,
@db_volume int,
@db_dt smalldatetime,
@db_close real,
@db_mult real,
@db_avg real,
@db_index real,
@db_rank smallint,
@db_mult_avg_ratio real,
@db_rank_change smallint,
@db_change_rank smallint'',
	@db_ticker_id,
@db_volume,
@db_dt,
@db_close,
@db_mult,
@db_avg,
@db_index,
@db_rank,
@db_mult_avg_ratio,
@db_rank_change,
@db_change_rank


	select @retval = @@ROWCOUNT
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_Delete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE  [dbo].[csp_tbl_BSE_Prices_Delete]
(
	@db_row_id int=NULL,
	@retval int output		
) 
As
	if @db_row_id IS NULL
	begin
		raiserror (''Please provide a key to delete a record in tbl_BSE_Prices.'', 16, 1)
		return
	end

	

	Declare @sql nvarchar(4000)

	set @sql = N''delete from dbo.tbl_BSE_Prices'' + '' '' + '' where db_row_id = @db_row_id ''
	set @sql = @sql + '' '' + '' '' 

	exec @retval = sp_executesql @sql,
	N''@db_row_id int '',
	@db_row_id

	select @retval = @@ROWCOUNT
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_Delete_Where]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
Create PROCEDURE  [dbo].[csp_tbl_BSE_Prices_Delete_Where]
(
	@whereclause nvarchar(3000) = NULL,
	@db_Year int=-1,
	@retval int output		
) 
As

	Declare @sql nvarchar(4000)
	Declare @Comma nvarchar(1)
	set @Comma = N'' ''

	if @whereclause IS NULL
		BEGIN
			set @sql = N''delete from dbo.tbl_BSE_Prices''
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
		END
	else
		BEGIN
			set @sql = N''delete from dbo.tbl_BSE_Prices''			
			if @db_Year > 0 set @sql = @sql + CAST(@db_Year as nchar(4))
			set @sql = @sql + '' where ''			
			set @sql = @sql + @whereclause
		END
	exec sp_executesql @sql
	select @retval = @@ROWCOUNT

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_GetByID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [dbo].[csp_tbl_BSE_Prices_GetByID]
(
	@db_row_id int 
)
as
	if @db_row_id IS NULL
	begin
		raiserror (''Please provide a key to query tbl_BSE_Prices.'', 16, 1)
		return -101
	end

	

	Declare @cmd nvarchar(4000)

	set @cmd = N''select db_row_id, db_ticker_id, db_volume, db_dt, db_close, db_mult, db_avg, db_index, db_rank, db_mult_avg_ratio, db_rank_change, db_change_rank ''
	set @cmd = @cmd + N'' from dbo.tbl_BSE_Prices'' + '' ''
	set @cmd = @cmd + N'' where db_row_id = @db_row_id ''
	set @cmd = @cmd + '' ''
	exec sp_executesql @cmd,
	N''@db_row_id int '',
	@db_row_id

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_tbl_BSE_Prices_List]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [dbo].[csp_tbl_BSE_Prices_List]
(
	@cols nvarchar(2000) = NULL,
	
	@whereclause nvarchar(2000) = NULL

)
as
	Declare @sql nvarchar(4000)
	if @cols IS NULL
	BEGIN
	
		if @whereclause IS NULL
			BEGIN
				set @sql = N''select * from dbo.tbl_BSE_Prices''
			END
		else
			BEGIN
				Set @sql = N''select * from dbo.tbl_BSE_Prices where '' + @whereclause
			END
	END
	else
	BEGIN
		if @whereclause IS NULL
			BEGIN
				set @sql = N''select  '' + @cols + '' from dbo.tbl_BSE_Prices''
			END
		else
			BEGIN

				Set @sql = N''select ''
				Set @sql = @sql + @cols
				set @sql = @sql + '' from dbo.tbl_BSE_Prices where '' + @whereclause
			END
	END
	exec sp_executesql @sql

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_BSE_Ticker]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[tbl_BSE_Ticker](
	[db_ticker_id] [int] IDENTITY(1,1) NOT NULL,
	[db_scrip_cd] [int] NOT NULL,
	[db_scrip_name] [varchar](50) NULL,
 CONSTRAINT [PK_tbl_BSE_Ticker] PRIMARY KEY CLUSTERED 
(
	[db_ticker_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_BSE_Prices]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[tbl_BSE_Prices](
	[db_row_id] [int] IDENTITY(1,1) NOT NULL,
	[db_ticker_id] [int] NOT NULL,
	[db_volume] [int] NULL,
	[db_dt] [smalldatetime] NULL,
	[db_close] [real] NULL,
	[db_mult] [real] NULL,
	[db_avg] [real] NULL,
	[db_index] [real] NULL,
	[db_rank] [smallint] NULL,
	[db_mult_avg_ratio] [real] NULL,
	[db_rank_change] [smallint] NULL,
	[db_change_rank] [smallint] NULL,
 CONSTRAINT [PK_tbl_BSE_Prices] PRIMARY KEY CLUSTERED 
(
	[db_row_id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_BSE_Prices_tbl_BSE_Ticker_TickerID]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_BSE_Prices]'))
ALTER TABLE [dbo].[tbl_BSE_Prices]  WITH CHECK ADD  CONSTRAINT [FK_tbl_BSE_Prices_tbl_BSE_Ticker_TickerID] FOREIGN KEY([db_ticker_id])
REFERENCES [dbo].[tbl_BSE_Ticker] ([db_ticker_id])
GO
/****** Object:  Table [dbo].[tbl_BSE_Trades]    Script Date: 05/08/2011 01:05:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_BSE_Trades](
	[iid] [int] NOT NULL,
	[id] [int] NULL,
	[ticker_id] [int] NULL,
	[strTicker] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[bdate] [datetime] NULL,
	[bprice] [decimal](9, 2) NULL,
	[brank] [int] NULL,
	[bBuy] [tinyint] NULL,
	[sdate] [datetime] NULL,
	[sprice] [decimal](9, 2) NULL,
	[srank] [int] NULL,
	[gain] [decimal](9, 2) NULL,
	[ratio] [decimal](9, 2) NULL,
	[sratio] [decimal](9, 2) NULL,
	[typ] [smallint] NULL,
	[cnt] [int] NULL,
	[sp_rank] [int] NULL,
	[mean_sp_rank] [int] NULL,
	[nshares] [int] NULL,
	[buy_amount] [decimal](9, 2) NULL,
 CONSTRAINT [PK_tbl_BSE_Trades] PRIMARY KEY CLUSTERED 
(
	[iid] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
