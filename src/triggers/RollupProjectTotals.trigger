/*
11/9/12    CC    Created per 70065
*/
trigger RollupProjectTotals on Opportunity (after insert, after update, after delete, after undelete) {

    Opportunity[] TrigSet;
    if(trigger.isDelete)
        TrigSet = Trigger.Old; 
    else
        TrigSet = Trigger.New;
        
    Set<id> ProjIds = new Set<id>();
    for(Opportunity o : TrigSet){
        if(o.Project__c != null) ProjIds.add(o.Project__c);
    }
    
    Map<id,project__c> ProjMap = new Map<id,project__c>(
        [Select id, Project_Total__c, Closed_Won__c, Closed_Lost__c From Project__c Where id in :ProjIds]
    ); 
    
    //zero values
    for(Project__c p : ProjMap.values()){
        p.Project_Total__c = 0;
        p.Closed_Won__c = 0;
        p.Closed_Lost__c = 0;
    }
    
    Opportunity[] OppList = [Select Id, Project__c, StageName, Amount From Opportunity Where Project__c in :ProjIds];
    
    for(Opportunity o : OppList){
        
        if(o.Project__c == null) continue;
        
        Project__c Proj = ProjMap.get(o.Project__c);
        
        Proj.Project_Total__c += o.Amount;
        if(o.StageName == 'Closed Won') Proj.Closed_Won__c += o.Amount;
        if(o.StageName == 'Closed Lost') Proj.Closed_Lost__c += o.Amount;
    }
    
    Update ProjMap.values();
    
    
}