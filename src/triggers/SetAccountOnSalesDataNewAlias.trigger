/*
2/11/13    CC    Created per 78415
*/
trigger SetAccountOnSalesDataNewAlias on Distributor_Alias__c (after insert) {

    Distributor_Alias__c NewDA = trigger.new[0];
    
    Sales__c[] SalesData = [select Distributor__c From Sales__c Where Distributor_Txt__c = :NewDA.Name];
    
    for(Sales__c sd : SalesData){
        sd.Distributor__c = NewDA.Distributor__c;
    }
    
    Update SalesData;
    
}