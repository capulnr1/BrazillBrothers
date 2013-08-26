/*
Trigger to set Sales object owner based on their distributor owner. 
07/01/13 RT@IC Created Trigger (Case 80143)
*/

trigger SetAccountOwner on Sales__c (After insert, After update) {
    Sales__c[] SalesToUpdate = new List<Sales__c>();
    for(Sales__c s : trigger.new){
        if(s.distributor__c != null){
            Sales__c UpdatedSales = s;
            UpdatedSales.ownerId = s.distributor__r.ownerid;
            SalesToUpdate.add(UpdatedSales);
        }
    }
    if(!SalesToUpdate.isEmpty()){
        update SalesToUpdate;   
    }
}