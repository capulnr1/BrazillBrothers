@isTest
private class TestImportToolCtrl{
    
    static testMethod void importCtrl(){
        Recordtype rt = [SELECT id, name 
                         FROM recordType 
                         WHERE DeveloperName = 'Principal'];
        
        Account testAcct = new Account(name = 'TestAccount', 
                                       recordtypeid = rt.id);
        insert testAcct;
        
        Import_Profile__c ipTest = new Import_Profile__c(name = 'ipTest',
                                                         CSV_Position__c = '2', 
                                                         Field_Name__c = 'startAtRow' , 
                                                         Principal_Id__c = testAcct.id);
        
        Import_Profile__c ipTest2 = new Import_Profile__c(name = 'ipTest2',
                                                          CSV_Position__c = 'a', 
                                                          Field_Name__c = 'commission__c' , 
                                                          Principal_Id__c = testAcct.id);
        
        Import_Profile__c ipTest3 = new Import_Profile__c(name = 'ipTest3',
                                                          CSV_Position__c = 'b', 
                                                          Field_Name__c = 'distributor_state__c' , 
                                                          Principal_Id__c = testAcct.id);
        
        // TEST DATE VALUE LATER Import_Profile__c ipTest = new Import_Profile__c(CSV_Position__c = 'c', Field_Name__c = 'startAtRow' , Principal_Id__c = testAcct.id);
        
        insert new list<Import_Profile__c>{ipTest, ipTest2, ipTest3};
            
        importToolCtrl itc = new importToolCtrl();
        itc.getProfiles();
        itc.contentFile = blob.valueOf('96197,United Electric Supply,MD,21227,405.11,24.9\r109557,United Electric Supply,MD,20794,213.45,10.68\r102437,Dominion Electric Supply,MD,20707,1074.52,26.86');
        itc.profile = testAcct.id;
        itc.ParseData();
        itc.contentFile = blob.valueOf('96197,,MD,21227,405.11,24.9\r109557,United Electric Supply,MD,20794,213.45,10.68\r102437,Dominion Electric Supply,MD,20707,1074.52,26.86');
        itc.ParseData();
        itc.profile = null;
        itc.ParseData();
    }
}