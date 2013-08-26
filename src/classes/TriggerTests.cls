/*
11/9/12    CC    Created per 70065 and 70068  
12/18/13   CC    Add method for 78415  
2/23/12    CC    Add method for Custom Account Owner
*/
public class TriggerTests{

    @isTest
    static void testRollupProjectTotals(){
        
        System.debug('@@@@ Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        
        Project__c p = new Project__c(Name = 'CC Project');
        Insert p;
        
        Opportunity oppa = new Opportunity(
            Name = 'CC Opp A'
            , Project__c = p.id
            , StageName = 'Identified'
            , CloseDate = System.Now().addDays(30).Date()
            , Amount = Decimal.valueOf('111.00')
        );
        
        Opportunity oppb = new Opportunity(
            Name = 'CC Opp B'
            , Project__c = p.id
            , StageName = 'Identified'
            , CloseDate = System.Now().addDays(30).Date()
            , Amount = Decimal.valueOf('222.00')
        );
        
        //initial insert
        Insert oppa;
        Insert oppb;  
        
        p = [Select id, Project_Total__c, Closed_Won__c, Closed_Lost__c From Project__c Where id = :p.id];
        System.assertEquals(Decimal.valueOf('333.00'), p.Project_Total__c);
        System.assertEquals(Decimal.valueOf('0.00'), p.Closed_Won__c);
        System.assertEquals(Decimal.valueOf('0.00'), p.Closed_Lost__c);
        
        //update stages
        oppa.StageName = 'Closed Won';
        oppb.StageName = 'Closed Lost';
        Update new Opportunity[]{oppa,oppb};
        
        p = [Select id, Project_Total__c, Closed_Won__c, Closed_Lost__c From Project__c Where id = :p.id];
        System.assertEquals(Decimal.valueOf('333.00'), p.Project_Total__c);
        System.assertEquals(Decimal.valueOf('111.00'), p.Closed_Won__c);
        System.assertEquals(Decimal.valueOf('222.00'), p.Closed_Lost__c);
        
        //update amounts and stages
        oppa.StageName = 'Closed Lost';
        oppa.Amount = Decimal.valueOf('333.00');
        oppb.StageName = 'Closed Lost';
        oppb.Amount = Decimal.valueOf('444.00');
        Update new Opportunity[]{oppa,oppb};
        
        p = [Select id, Project_Total__c, Closed_Won__c, Closed_Lost__c From Project__c Where id = :p.id];
        System.assertEquals(Decimal.valueOf('777.00'), p.Project_Total__c);
        System.assertEquals(Decimal.valueOf('0.00'), p.Closed_Won__c);
        System.assertEquals(Decimal.valueOf('777.00'), p.Closed_Lost__c);
        
        //delete
        delete oppa;
        
        p = [Select id, Project_Total__c, Closed_Won__c, Closed_Lost__c From Project__c Where id = :p.id];
        System.assertEquals(Decimal.valueOf('444.00'), p.Project_Total__c);
        System.assertEquals(Decimal.valueOf('0.00'), p.Closed_Won__c);
        System.assertEquals(Decimal.valueOf('444.00'), p.Closed_Lost__c);
        
    }
    
    @isTest
    static void SetAccountOnSalesData(){
    
        System.debug('@@@@ Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    
        Account a = new Account(Name = 'CC Distributor');
        Insert a;
        
        Distributor_Alias__c da = New Distributor_Alias__c(
            Name = 'CC Distro'
            , Distributor__c = a.id
        );
        Insert da;
        
        //two sales items - one with complete name, one with alias
        Sales__c sda = new Sales__c(
            Distributor_Txt__c = 'CC Distributor'
        );
        
        Sales__c sdb = new Sales__c(
            Distributor_Txt__c = 'CC Distro'
        );
        
        Insert new Sales__c[]{sda,sdb};
    
        System.assertEquals(2, [Select id from Sales__c where Distributor__c = :a.id].size());
    
    }
    
    @isTest
    static void testSetAccountOnSalesDataNewAlias(){
    
        System.debug('@@@@ Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        
        Sales__c sd = new Sales__c(
            Distributor_Txt__c = 'TBD123'
        );
        Insert sd;
        
        Account a = new Account(Name = 'CC Distributor');
        Insert a;
        
        Distributor_Alias__c da = New Distributor_Alias__c(
            Name = 'TBD123'
            , Distributor__c = a.id
        );
        Insert da;
        
        sd = [Select id, Distributor__c From Sales__c where id = :sd.id];
        system.assertEquals(a.id, sd.Distributor__c);
    
    }
    
    @isTest
    static void testSetCustomAccountOwner (){

        User[] users = [SELECT id, name, email FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' Limit 2];
        
        User u1 = users[0];
        //User u2 = users[1]
        
        //insert new account
        Account a = new Account(
            Name = 'Trigger test account',
            OwnerId = u1.id
        );
        Insert a;
        
        //check custom field after insertion
        a = [SELECT Name, OwnerId, Owner__c FROM Account WHERE id = :a.id];
        System.assert(a.Owner__c == u1.id);
        
        //change owner and recheck for updated custom field
        /*
        a.OwnerId = u2.id;
        Update a;
        a = [SELECT Name, OwnerId, Account_Owner__c FROM Account WHERE id = :a.id];
        System.assert(a.Owner__c == u2.id);
        */
        
    }
   
}