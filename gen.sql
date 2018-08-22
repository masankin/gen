 
CREATE PROCEDURE [gen_issue]
	@code varchar(20),
	@num int
AS
BEGIN 	
    declare @msg varchar(200)  set @msg = '';
	declare @msg_open varchar(200)  set @msg_open = '';
	declare @msg_geninfo varchar(200)  set @msg_geninfo = ''; 
	declare @lot_id int
	declare @lott_cn varchar(20)
			
	select @lot_id =  id,@lott_cn=name from temp_lot where  code = @code 
	 
	CREATE table #temp_lot_issue  
	(id int identity(1,1),
	 lott_name varchar(20),
	 issue varchar(20),
	 ed_time varchar(20),
	 op_time varchar(20),
	 offset int) 
	 CREATE INDEX temp_lot_issue_INDEX  ON #temp_lot_issue(id)
	  
    insert into #temp_lot_issue  
        select lott_name,issue,ed_time,op_time,offset
		from dbo.lot_openTime where lot_id = @lot_id
	
	  
	declare @i int  
	declare @up int 
	declare @daynum int 
	declare @seek int 
	declare @tobe_ed_time varchar(20) 
	declare @n int 
	declare @is_jump int 
	declare @nowtime datetime 
	declare @nowtime_ymd varchar(20)
	declare @nowtime_y varchar(4) 
	declare @nowtime_y_preissue varchar(20) 
	declare @nowtime_y_curissue varchar(20) 
	declare @nowtime_week varchar(5)  
	declare @common_list varchar(1000) set @common_list = ''
	declare @auto_increase_list varchar(1000) = '' 
	declare @startissue varchar(20)
	set @i = 0
	set @up = 0
	set @n = 0
	set @seek = 0
	set @nowtime =  getdate()
	set @nowtime_ymd = 	convert(varchar(8),@nowtime,112) --yyyyMMdd
	set @nowtime_y = 	LEFT(@nowtime_ymd,4) --yyyy 
	set @nowtime_y_preissue = @nowtime_y
	 
	if(CHARINDEX('['+@code+']',@auto_increase_list) > 0)
    begin
		select top 1 @startissue = issue from lot_open where lot_id = @lot_id order by issue desc
	    set @msg_open =  'latest open:'+@startissue
	    if(@code = 'auto_increase_code')
		begin
		  set @startissue =  RIGHT(@startissue,3)
		end
	end
	
	
	select @daynum = MAX(id) from #temp_lot_issue
	select top 1 @seek = id,@tobe_ed_time = ed_time from #temp_lot_issue 
			where offset is null or offset = 0 order by
			abs(datediff(ss,ed_time,convert(varchar(20),getdate(),108))) 
	if(@seek = 0) 
	begin 
		set @n = 1
	end 
	
	set @msg_geninfo = 'pre day total issue:'+convert(varchar(20),@daynum)+
	      '   gen issue count:'+convert(varchar(20),@num)+
	      '   latest end:'+@tobe_ed_time+
	      '   index:'+convert(varchar(20),@seek)			
   begin tran
		while @i <= @num begin 
			 
		    set @is_jump = 0  
			if( CHARINDEX('['+@code+']',@common_list) > 0 or
			    CHARINDEX('['+@code+']',@auto_increase_list) > 0)
			begin
			   -- print @seek
			    
			    if(@seek > @daynum)
				begin
				  set @n = @n+1
				  set @seek = 1 -- reset
				end
				
				declare @_@issue varchar(20)
				declare @_@ed_time varchar(20)
				declare @_@op_time varchar(20)
				declare @_@offset int
				
				select @_@issue=issue,@_@ed_time=ed_time,@_@op_time=op_time,@_@offset=ISNULL(offset,0) from #temp_lot_issue 
				where id = @seek 
				
				declare @_@@offset int set @_@@offset = @_@offset + @n -- offset + n , both effect
				
				declare @_@@issue varchar(20)
				declare @_@@op_time varchar(20)
				declare @_@@ed_time varchar(20) 
				
				
				if(@_@offset != 0 )
				begin
				     
				     declare @_@@op_time_out int
				      
				     select @_@@op_time_out = datediff(ss,ed_time,op_time) from  #temp_lot_issue where id = @seek
				      
				     --@_@@op_time_out < 0 => ed_time  >  op_time  => ed_time no over,  op_time over day
				     --@_@@op_time_out > 0 => ed_time  <  op_time => all over,  ed_time  op_time  over day
				     
				     --print @_@@op_time_out 
				     if(@_@@op_time_out < 0)
				     begin
				        if(@_@offset < 0) --  < 0 => end = + @_@offset 
				        begin
				            set @_@@ed_time= convert(varchar(20),dateadd(day,@n + @_@offset,@nowtime),111) + ' ' + @_@ed_time
							set @_@@op_time= convert(varchar(20),dateadd(day,@n,@nowtime),111) + ' ' + @_@op_time
				        end
				        if(@_@offset > 0)
				        begin
				            set @_@@ed_time= convert(varchar(20),dateadd(day,@n,@nowtime),111) + ' ' + @_@ed_time
							set @_@@op_time= convert(varchar(20),dateadd(day,@_@@offset,@nowtime),111) + ' ' + @_@op_time
				        end
				         
				     end
				     if(@_@@op_time_out > 0)
				     begin
				        set @_@@ed_time= convert(varchar(20),dateadd(day,@_@@offset,@nowtime),111) + ' ' + @_@ed_time
				        set @_@@op_time= convert(varchar(20),dateadd(day,@_@@offset,@nowtime),111) + ' ' + @_@op_time
				     end
				end
				else
				begin
				   set @_@@op_time= convert(varchar(20),dateadd(day,@n,@nowtime),111) + ' ' + @_@op_time
				   set @_@@ed_time= convert(varchar(20),dateadd(day,@n,@nowtime),111) + ' ' + @_@ed_time
				end
				 
				 
				--BEGIN 
				--general
				if(CHARINDEX('['+@code+']',@common_list) > 0)
				begin
				
				    if(@code = '')
				    begin
				      set @_@issue = RIGHT('00000'+@_@issue,2)
				    end
				    else
				    begin
				     set @_@issue = @_@issue -- at least leave 3
				    end
				    set @_@@issue = convert(varchar(8), dateadd(day,@n,@nowtime_ymd),112)
				       + @_@issue -- do not use offset correct, the n day
				
				-- leave 2
				end
				if(CHARINDEX('['+@code+']',@auto_increase_list) > 0)
				begin
				  --yyyyxxx
				  if(@code = 'end4code' )
				  begin
				    set @nowtime_y_curissue = LEFT(@_@@ed_time,4)--convert(datetime,@_@@ed_time,121) 
				    declare @@et datetime set @@et = CONVERT(datetime,@_@@ed_time)
				    set datefirst 1 --Must
				    set @nowtime_week = CONVERT(varchar(2),datepart(weekday,@@et))
				    declare @distance int  set @distance = CONVERT(int,@nowtime_y_curissue) - CONVERT(int,@nowtime_y_preissue)
				    
				    if(@distance > 0)-- over year, start from 0 isslue
				    begin
				          --print @nowtime_y_curissue
				          --print @up
						  set @seek = 1 -- reset
						  set @up = 0 ---- reset
						  set @startissue = 0 -- reset
					end
					if(@code = '246code')-- 2,4,6
					begin
					   if(@nowtime_week = '2'  or @nowtime_week = '4' or @nowtime_week = '6')
					   begin
					     set @is_jump = 0
					   end
					   else 
					   begin 
					      set @is_jump = 1
					   end
					   
					end 
					
					if(@code = '257code') -- 2,5,7
					begin
					   if(@nowtime_week = '2'  or @nowtime_week = '5' or @nowtime_week = '7')
					   begin
					     set @is_jump = 0 --
					   end
					   else 
					   begin
					      set @is_jump = 1
					   end
					   
					end 
					   
				     
				    declare @_@@@issuenum int set @_@@@issuenum = convert(int,@startissue) + @up + 1
				    declare @_@@@issue varchar(5) set  @_@@@issue = CONVERT(varchar(5),@_@@@issuenum) -- +1
				    
				     
				    set @_@@@issue = RIGHT('00000'+@_@@@issue,3) --At least leave three
				    --print @_@@@issue
				    set @_@@issue = @nowtime_y_curissue + @_@@@issue
				    
				    set @nowtime_y_preissue = @nowtime_y_curissue
				  end
				  --xxxxxx
				  if(@code = 'autoadd1code')
				  begin
				    set @_@@issue =  convert(numeric,@startissue) + @up + 1 -- +1
				  end
				  
				end
				------------END
                    
				if(@is_jump = 0) 
				begin
				    --print @_@@issue   --yyyMMdd 112
				    --  + '   '+@_@@ed_time
				    --  + '   '+@_@@op_time
				    insert  into  temp_daily_lot_issue (issue,ed_time,op_time,code)  values(@_@@issue,@_@@ed_time,@_@@op_time,@code)
				    
				    if(@i = 0)
				    begin
				      set @msg_geninfo = @msg_geninfo + '  start issue:'+ @_@@issue
				    end
				    
				end 
				set @seek = @seek + 1 -- seek increasing   
			end
			
			 
			set @i = @i+1
			if(@is_jump = 0) 
			begin
			   set @up = @up+1
			end
	end 
    commit tran
    
			select @msg = @lott_cn +
			   (case COUNT(*) 
			   when 0 
			   then 
			      ':'+CONVERT(varchar(10),COUNT(*))+' Issue'
			      
			   else 
			    ' SUCCESS:'+CONVERT(varchar(10),COUNT(*))+' Issue'
			   end)
			from temp_daily_lot_issue where code = @code and issue is not null  
    drop table #temp_lot_issue    
select @msg msg,@msg_open msg_open,@msg_geninfo msg_geninfo;

END



