/*
11/8/12    CC    Created per 70065
*/
public class CreateOppsCtrl{

    final Project__c Proj;
    final RecordType RecType = [Select Id from RecordType where DeveloperName = 'Construction_Project' and SobjectType = 'Opportunity' limit 1];
                
    public Opportunity[] OppList {get;set;}
    
    public CreateOppsCtrl(ApexPages.StandardController con){
        
        Proj = [select id, name from Project__c where id = :con.getRecord().id];
        
        OppList = New Opportunity[]{};

        Account[] PrinList = [Select id, Name,  Abbrev__c from Account 
            Where RecordType.DeveloperName = 'Principal' and MO_Ord__c != null
            Order By MO_Ord__c];
        
        Opportunity[]  ExistingOpps = [Select Name, AccountId, Distributor__c, Principal__c, StageName, CloseDate, Amount 
                From Opportunity
                Where Project__c = :Proj.Id];
        
        Map<id,Opportunity> ExistingPrins = new Map<id,Opportunity>();
        
        for(Opportunity o : ExistingOpps){
            ExistingPrins.put(o.Principal__c,o);
        }
            
        for(Account Prin : PrinList){
            if(ExistingPrins.containsKey(Prin.id)){
                OppList.add(ExistingPrins.get(Prin.id));
            }
            else{
                OppList.add(new Opportunity(
                    Name =  Prin.Abbrev__c + ' - ' + proj.Name
                    , Principal__c = Prin.Id
                    , Project__c = Proj.Id 
                    , StageName = 'Identified'
                    , CloseDate = System.Now().addDays(30).Date()
                    , RecordTypeId = RecType.id 
                ));
            }
        
        }
        
    }

    public PageReference saveAll(){
    
        //validation
        Boolean hasErrors = false;
        for(Opportunity o : OppList){ 
            if(o.Amount != null && o.Amount != 0 && o.AccountId == null){
                hasErrors = true;    
                o.AccountId.addError('You must enter a value.');
            }
        }     
        if(hasErrors) return null;
        
        //store separate lists of items to upsert and to delete
        Opportunity[] SaveList = New Opportunity[]{};
        Opportunity[] DelList = New Opportunity[]{};
        
        for(Opportunity o : OppList){ 
            if(o.Amount != null && o.Amount != 0){
                SaveList.add(o);
            }
            else{
                if(o.id != null) DelList.add(o);
            }
        
        }
        
        upsert SaveList;
        delete DelList;
        
        return new PageReference('/' + Proj.Id);
    }
    
    public PageReference canc(){
        return new PageReference('/' + Proj.Id);
    }
    
    @isTest(seeAllData = true)
    static void runTests(){
    
        Account a = new Account(
            Name = 'CC Distributor'
            , RecordTypeId = [select id from RecordType Where DeveloperName = 'Contractor'].id
        );
        Insert a;
        
        Project__c p = new Project__c(Name = 'CC Project');
        Insert p;
        
        ApexPages.StandardController sc = new ApexPages.StandardController([select id from Project__c where id = :p.id Limit 1]);
        
        CreateOppsCtrl coc = new CreateOppsCtrl(sc);

        //test error handling - no account
        coc.OppList[0].Amount = Decimal.valueOf('100.00'); 
        system.assertEquals(null, coc.saveAll());    
        
        //successful save
        coc.OppList[0].AccountId = a.id;
        coc.saveAll();    
        
        //reload page with saved opps and check value
        coc = new CreateOppsCtrl(sc);
        system.assertEquals(Decimal.valueOf('100.00'), coc.OppList[0].Amount);
        
        coc.canc();
        
    }

}