ALTER PROCEDURE dbo.ask_jira_closed_fix
as
BEGIN
	set nocount on
	set fmtonly off
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    create table #t(
    		issueid     	int,
            priority    	int,
            k           	decimal(18,4),
            assignee    	varchar(255),
            summary     	varchar(255),
            ddate			datetime,
            action      	varchar(255),
            artefact    	varchar(255),
            system      	varchar(255),
            num_col     	decimal(18,4),
            nt          	int,
            new_summ    	decimal(18,4), 
            col_base    	decimal(18,4),
            parent_issueid 	int,
            issuetype       int
    )
    

    insert into #t(
    	issueid     ,
        priority    ,
        assignee    ,
        summary     ,
        ddate
    )
    select
			i.id             issueid,
            i.PRIORITY       priority,
            i.ASSIGNEE       assignee ,
            i.SUMMARY        summary,
            cg.CREATED       ddate
	from
	            dbo.jiraissue i
				join dbo.changegroup cg on i.ID = cg.issueid
				join dbo.changeitem ci  on cg.id = ci.groupid 
	where
			    i.issuetype = 5 and 
			   	i.project = 10030 and
			    ci.FIELD = 'status' and
			    convert(varchar(255), ci.newvalue) = '6'
	  	
   delete #t where exists( select 1 from #t tt where tt.issueid = #t.issueid and tt.ddate < #t.ddate)
  			
   update 
   			#t
   	  set
   	  		k = case convert(int, priority)
				when 1 then	2    --Чрезвычайный
				when 2 then	1.5  --Угрожающий
				when 3 then	1    --Значительный
				when 4 then	0.75 --Малозначительный
				when 5 then	0.5  --Незначительный
			end
			
   	        
   	  update
   	  		#t
   	  set 
   	  		nt =   len(summary) - len(replace(summary,',','')) + 1 
   	  		
   	  update
   	  		#t
   	  set 		
   	  		artefact = cfo_parent.customvalue + ' ' + cfo_stringvalue.customvalue
   	  from
   	        dbo.customfieldvalue cfv   
			join dbo.customfieldoption cfo_parent on  convert(varchar(10), cfo_parent.id) = cfv.parentkey
			                                                  and cfo_parent.CUSTOMFIELD = cfv.CUSTOMFIELD
			join dbo.customfieldoption cfo_stringvalue on  convert(varchar(10), cfo_stringvalue.id) = cfv.stringvalue
			                                                       and cfo_stringvalue.CUSTOMFIELD = cfv.CUSTOMFIELD		   
   	  where
   	  		cfv.issue = #t.issueid and 
   	  		cfv.CUSTOMFIELD = 10320

   	  update
   	  		#t
   	  set 		
   	  		artefact = cfo_stringvalue.customvalue
   	  from
   	        dbo.customfieldvalue cfv   
			join dbo.customfieldoption cfo_stringvalue on  convert(varchar(10), cfo_stringvalue.id) = cfv.stringvalue
			                                                       and cfo_stringvalue.CUSTOMFIELD = cfv.CUSTOMFIELD		   
   	  where
   	  		cfv.issue = #t.issueid and 
   	  		cfv.CUSTOMFIELD = 10320 and
   	  		#t.artefact is null
   	  		   
 	  update
   	  		#t
   	  set 		
   	  		action = cfv.STRINGVALUE
   	  from
   	        dbo.customfieldvalue cfv  		   
   	  where
   	  		cfv.issue = #t.issueid and 
   	  		cfv.CUSTOMFIELD = 10323 
   	  		
   	  update
   	  		#t
   	  set 		
   	  		system = cfv.STRINGVALUE
   	  from
   	        dbo.customfieldvalue cfv  		   
   	  where
   	  		cfv.issue = #t.issueid and 
   	  		cfv.CUSTOMFIELD = 10322 
   	  
   	  update
   	  		#t
   	  set 		
   	  		new_summ = ba.summ,
   	  		col_base = ba.col_base
   	  from 
   	  		dbo.base_artefact ba
   	  where 
   	  		ba.artefact = #t.artefact and
   	  		ba.action   = #t.action
   	  		
   	  update
   	  		#t
   	  set 		
   	  		new_summ = ba.summ
   	  from 
   	  		dbo.base_artefact ba
   	  where 
   	  		ba.artefact is NULL     and
   	  		ba.action   = #t.action and
   	  		#t.new_summ is NULL
   	  		
   	  update
   	  		#t
   	  set 		
   	  		new_summ = new_summ + 100
   	  where 		
   	  		system = 'Payroll'	

   	  update
   	  		#t
   	  set 		
   	  		new_summ = new_summ * nt

   	  update
   	  		#t
   	  set 		
   	  		new_summ = new_summ + 350
   	  where 		
   	  		summary like '%w_tab_wzrec%'	
   
   update
   	  		#t
   	  set 		
   	  		new_summ = new_summ + 350
   	  where 		
   	  		(summary like '%calc_bp'  or summary like '%wms_flashback'  or summary like '%palm_OrdProcess' or
   	  		 summary like '%calc_bp,%' or summary like '%wms_flashback,%' or summary like '%palm_OrdProcess,%') and
   	  		artefact = 'SQL SP'
   	  		
   update
   	  		#t
   	  set 		   	  		
   			parent_issueid = il.SOURCE
	from
			dbo.issuelink il
	where
			il.DESTINATION = #t.issueid and 
			il.LINKTYPE = 10000	
				
	update
			#t
	set
			new_summ = new_summ * 2
	from
			dbo.nodeassociation node 
			join dbo.component c on c.id = node.SINK_NODE_ID and node.SINK_NODE_ENTITY = 'Component'
	where
			node.SOURCE_NODE_ID     =  #t.parent_issueid and
			node.SOURCE_NODE_ENTITY = 'Issue' and 
			c.cname = 'Spree'
	  		
    update
   	  		#t
   	  set 		
   	  		num_col = cfv.numbervalue
   	  from
   	        dbo.customfieldvalue cfv  		   
   	  where
   	  		cfv.issue = #t.issueid and 
   	  		cfv.CUSTOMFIELD = 11030
   	  		
    update
   	  		#t
   	   set 		
   	  		new_summ = new_summ + num_col*col_base
   	 where
   	   		num_col > 0 and col_base > 0
   	   		
    update
   	  		#t
   	   set 		
   	  		new_summ = new_summ * k
   	  		
    update
   	  		#t
   	   set 		
   	  		issuetype = i.issuetype
   	from
	        dbo.jiraissue i
	where
			#t.parent_issueid = i.id
				
   	delete dbo.factBonusDev		
   	
   	insert into dbo.factBonusDev (date_uid,person_uid,issuetype_uid,bonustype_uid,bonus,issueid)
	select
	         ISNULL(MAX(dimDate.DateKey),-1) date_uid,
	         ISNULL(dimPerson.uid,-1) person_uid,
	         ISNULL(dimIssueType.uid,-1) issuetype_uid,
	         17 bonustype_uid,
	         sum(#t.new_summ) bonus,
	         #t.parent_issueid issueid
	from #t
	        left outer join dimDate on dimDate.FullDate = DATEADD(dd, 0, DATEDIFF(dd, 0, #t.ddate))
	        left outer join dimPerson on dimPerson.ADname = #t.assignee
	        left outer join dimIssueType on dimIssueType.issuetype_id = #t.issuetype and dimIssueType.project_id = 10030
	where #t.new_summ > 0
	group by #t.parent_issueid, dimPerson.uid, dimIssueType.uid;
	  		   	  		   	  		
   	
end