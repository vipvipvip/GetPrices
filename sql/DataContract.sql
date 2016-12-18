/*
This script creates a C# class for a Data Contract for a SQL Table
*/
declare @tblName varchar(20)
set @tblName = 'tbl_stats'
declare @objId int

select @objId = object_id from StockDB.sys.tables where name = @tblName

declare @tbl TABLE (idx int identity, colname varchar(50), isNullable bit, typename varchar(25))

insert @tbl
select C.name, C.is_nullable, TYPES.name
from StockDB.sys.columns C, StockDB.sys.types TYPES
where C.object_id = @objId
and C.system_type_id = TYPES.user_type_id
order by C.column_id


select * from @tbl


declare @tplSTART varchar(100)
declare @tplMIDDLE varchar(100)
declare @tplEND varchar(100)

declare @clsMIDDLE varchar(max)
set @clsMIDDLE = '';

declare @tempMIDDLE varchar(100)
set @tempMIDDLE = '';

set @tplSTART =  ' 
	[DataContract]
    class %TABLENAME%
    { '


set @tplMIDDLE = '
        
		[DataMember]
        public %TYPE%%NULLABLE% %COLNAME%  { get; set; }'

set @tplEND = '
	};'


declare @i int
set @i = 1

declare @c varchar(50)
declare @t varchar(25)
declare @bNullable bit
declare @nullChar char(1)

while exists(select * from @tbl where idx = @i)
  begin
	select @c = colname, @bNullable = isNullable,  @t=typename from @tbl where idx = @i
	set @nullChar =  case @bNullable when 1 then '?' else '' end;

	if (PATINDEX('%varchar%', @t) > 0)
	  begin
		set @tempMIDDLE = REPLACE(@tplMIDDLE, '%TYPE%', 'string')
		set @tempMIDDLE = replace(@tempMIDDLE, '%NULLABLE%', @nullChar);
		--set @tempMIDDLE = @tempMIDDLE + ' = "";'
	  end
	else 	if (PATINDEX('%datetime%', @t) > 0)
	  begin
		set @tempMIDDLE = REPLACE(@tplMIDDLE, '%TYPE%', 'DateTime')
		set @tempMIDDLE = replace(@tempMIDDLE, '%NULLABLE%', @nullChar);
--		set @tempMIDDLE += ';'
	  end
	else
	  begin 
		set @tempMIDDLE = REPLACE(@tplMIDDLE, '%TYPE%', @t)
		set @tempMIDDLE = replace(@tempMIDDLE, '%NULLABLE%', @nullChar);
--	  	set @tempMIDDLE = @tempMIDDLE + ';'
	  end

	set @tempMIDDLE = REPLACE(@tempMIDDLE, '%COLNAME%', @c)

	-- final clean up to make C# happy
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'int', 'long')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'smallint', 'long')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'real', 'Single')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'decimal', 'double')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'tinyint', 'Byte')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'money', 'decimal')
	set @tempMIDDLE = REPLACE(@tempMIDDLE, 'numeric', 'long')


	set @i = @i + 1
	set @clsMIDDLE = @clsMIDDLE + @tempMIDDLE
  end



print replace( @tplSTART, '%TABLENAME%', @tblName) + @clsMIDDLE + @tplEND


--select * from StockDB.sys.types order by system_type_id
--select * from StockDB.sys.tables where name = 'tbl_Ticker'
--select * from StockDB.sys.columns where object_id = 1945773989