@isTest
private class TestAssignDistributor{
    static testMethod void validateTrigger(){
        RecordType rt = [SELECT id FROM RecordType WHERE Developername = 'Distributor' AND sobjectType = 'Account'];
        Account acct = new Account(name = 'Testing', RecordTypeID = rt.id);
        insert acct;
        
        Distributor_Alias__c DA = new Distributor_Alias__c(Account_Number__c = '123456789', 
                                                           City__c = 'Hamilton', 
                                                           Distributor__c = acct.id,
                                                           Postal_Code__c = '08691',
                                                           State__c = 'NJ');
        insert DA;
        
        Sales__c firstSales = new Sales__c(Distributor_Txt__c = 'Testing',
                                           Distributor_City__c = 'Hamilton',
                                           Distributor_Zip__c = '08691',
                                           Distributor_State__c = 'NJ',
                                           Invoice_Number__c = '123456789',
                                           Total__c = 01.99,
                                           Trans_Date__c = Date.Today() - 50,
                                           Sales_Amount__c = 01.99,
                                           Commission__c = 00.25
                                          );
        insert firstSales;
        
        firstSales = [SELECT Distributor__c FROM Sales__c WHERE Invoice_Number__c = '123456789'];
        //Check if the Distributor is set on the Sales object by the trigger
        //System.assertEquals(firstSales.Distributor__c, acct.id);  
        
        firstSales.Distributor__c = null;
        update firstSales;
       
        firstSales.Distributor__c = acct.id;
        
        firstSales.Invoice_Number__c = '77777777';
        update firstSales;
        
        Distributor_Alias__c[] assertions = [SELECT id 
                                             FROM Distributor_Alias__c 
                                             WHERE Distributor__c = :acct.id];
        
        //Check to make sure there is two alias created now
        //System.assertEquals(assertions.size(), 2);
    }
}