public class TestData{

    public static Project__c proj {get;set;}
    public static Opportunity oppa {get;set;}
    public static Opportunity oppb {get;set;}
    
    static{ 
        
        proj = new Project__c(Name = 'CC Project');
        Insert proj;
        
        oppa = new Opportunity(
            Name = 'CC Opp A'
            , Project__c = proj.id
            , StageName = 'Closed Won'
            , CloseDate = System.Now().addDays(30).Date()
            , Amount = Decimal.valueOf('111.00')
        );
        
        oppb = new Opportunity(
            Name = 'CC Opp B'
            , Project__c = proj.id
            , StageName = 'Closed Lost'
            , CloseDate = System.Now().addDays(30).Date()
            , Amount = Decimal.valueOf('222.00')
        );
        
        Insert oppa;
        Insert oppb;
    
    
    }
    
    
}