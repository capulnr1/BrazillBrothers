@isTest
private class TestCIPCtrl{
    static testMethod void importCtrl(){
        RecordType rt = [SELECT id FROM RecordType WHERE Developername = 'Principal' AND sobjectType = 'Account'];
        Account acct = new Account(name = 'Testing', RecordTypeID = rt.id); 
        insert acct;
        
        Import_Profile__c ipTest = new Import_Profile__c(name = 'ipTest',
                                                         CSV_Position__c = '2', 
                                                         Field_Name__c = 'startAtRow' , 
                                                         Principal_Id__c = Acct.id);
        
        Import_Profile__c ipTest2 = new Import_Profile__c(name = 'ipTest2',
                                                          CSV_Position__c = 'a', 
                                                          Field_Name__c = 'commission__c' , 
                                                          Principal_Id__c = Acct.id);
        
        Import_Profile__c ipTest3 = new Import_Profile__c(name = 'ipTest3',
                                                          CSV_Position__c = 'b', 
                                                          Field_Name__c = 'distributor_state__c' , 
                                                          Principal_Id__c = Acct.id);
        
        Import_Profile__c ipTest4 = new Import_Profile__c(name = 'ipTest4',
                                                          Field_Name__c = 'invoice_number__c' , 
                                                          Principal_Id__c = Acct.id);
        
        insert new list<Import_Profile__c>{ipTest, ipTest2, ipTest3, ipTest4};
            
            CIPCtrl ccc = new CIPCtrl();
        ccc.getProfiles();
        
        ccc.save();
        
        Import_Profile__c ipTest5 = new Import_Profile__c(name = 'ipTest5',
                                                          CSV_Position__c = 'b',
                                                          Field_Name__c = 'distributor_state__c' , 
                                                          Principal_Id__c = Acct.id);
        
        insert ipTest5;
        ccc.getSettings();
        ccc.dupCheck();
        ccc.deleteProfile();
        ccc.pAccts = new Account[]{}; //no profiles selected
        ccc.getProfiles();
    }
}