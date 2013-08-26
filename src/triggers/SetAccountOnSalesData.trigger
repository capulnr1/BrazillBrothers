/*
11/9/12    CC    Created per 70068
2/22/13    CC    Null Dist Txt checks 78415
2/28/13    CC    Owner of Sales set to Distributor Owner
*/
trigger SetAccountOnSalesData on Sales__c (before insert) {

    //build list of account names
    Set<string> sdaccts = new Set<String>();
    for(Sales__c sd : Trigger.new){
        if(String.isBlank(sd.Distributor_Txt__c)) continue;
        sdaccts.add(sd.Distributor_Txt__c.trim());
    }
    
    //combined map for account names and tags
    Map<String,String> NameMap = new Map<string,string>();
    
    for(Account a : [Select Id, Name, OwnerId from Account where Name in :sdaccts]){
        NameMap.put(a.name, a.id);  
    }
    
    for(Distributor_Alias__c da : [Select Id, Name, Distributor__c, Distributor__r.OwnerId from Distributor_Alias__c where Name in :sdaccts]){
        NameMap.put(da.name, da.Distributor__c);
    }
    

    //set accounts
    for(Sales__c sd : Trigger.new){
        if(String.isBlank(sd.Distributor_Txt__c)) continue;
        sd.Distributor__c = NameMap.get(sd.Distributor_Txt__c.trim());  
    }
    
    //set owner to distributor owner - must run after Distributor is populated by above code
    Set<id> DistIds = New Set<id>();
    for(Sales__c sd : Trigger.new){
        if(sd.Distributor__c == null) continue;
        DistIds.add(sd.Distributor__c);
    }
    
    Map<Id,Account> OwnerMap = new Map<id,Account>([Select Id, OwnerId from Account Where Id in :DistIds]);
    
    for(Sales__c sd : Trigger.new){
        if(sd.Distributor__c == null) continue;
        sd.OwnerId = OwnerMap.get(sd.Distributor__c).OwnerId; //set owner
    }
    
}