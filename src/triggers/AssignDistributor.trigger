/*

Trigger to assign distributors to sales object.
Intelligently creates new alias for distributors.

06/03/13 RT@IC Initial creations (Case 83412)

*/

trigger AssignDistributor on Sales__c (before insert, before update) {
    if(trigger.isUpdate){//Check to see if need to create new alias
        Distributor_Alias__c[] AliasToAdd = new List<Distributor_Alias__c>();
		Distributor_Alias__c[] AliasToDelete = new List<Distributor_Alias__c>();//If alias exist already
		Set<Id> AliasToDeleteId = new Set<Id>(); //Make sure not to add the same alias to delete.
        
        for(Sales__c a : trigger.new){
            Sales__c beforeUpdate = System.Trigger.oldMap.get(a.Id);
            Distributor_Alias__c[] checkKey = [SELECT id 
                                               FROM Distributor_Alias__c 
                                               WHERE key__c = :a.key__c];
            
            if(!checkKey.isEmpty()){
                for(Distributor_Alias__c d : CheckKey){
                	AliasToDeleteId.add(d.id);
                }
            }
            
            //if(beforeUpdate.Distributor__c == null && a.Distributor__c != null && checkKey.isEmpty() == true){
            if(a.Distributor__c != null){
                String TempNewKey = '';
                Distributor_Alias__c newAlias = new Distributor_Alias__c();
                if(a.Invoice_Number__c != null){
                    newAlias.Account_Number__c = a.Invoice_Number__c;
                    TempNewKey += a.Invoice_Number__c;
                }
                if(a.Distributor_City__c != null){
                    newAlias.City__c = a.Distributor_City__c;
                    TempNewKey += a.Distributor_City__c;
                }
                if(a.Distributor_State__c != null){
                    newAlias.State__c = a.Distributor_State__c;
                    TempNewKey += a.Distributor_State__c;
                }
                if(a.Distributor_Zip__c != null){
                    newAlias.Postal_Code__c = a.Distributor_Zip__c;
                    TempNewKey += a.Distributor_Zip__c;
                }
                if(a.Distributor__c != null && a.Distributor_Txt__c != null){
                    Account[] DistributorName = [SELECT Name 
                                                FROM Account 
                                                WHERE id = :a.Distributor__c LIMIT 1];
                    if(!DistributorName.isEmpty()){
                        newAlias.Distributor__c = a.Distributor__c;
                        newAlias.Distributor_Txt__c = a.Distributor_Txt__c;
                        TempNewKey += a.Distributor_Txt__c;
                    }
                }
                if(a.Principal__c != null){
					newAlias.Principal__c = a.Principal__c;
                    TempNewKey += a.Principal__c;
                }
                Distributor_Alias__c[] dCheck = [SELECT id, name 
                                                 FROM Distributor_Alias__c 
                                                 WHERE key__c like :TempNewKey];
                if(dcheck.isEmpty()){//Make sure this alias does not exist already
                    if(newAlias.Account_Number__c != null 
                       || newAlias.City__c != null 
                       || newAlias.State__c != null
                       || newAlias.Postal_Code__c != null
                       || newAlias.Distributor__c != null
                       || newAlias.Distributor_Txt__c != null
                       || newAlias.Principal__c != null)
                        AliasToAdd.add(newAlias);
                }
            }
        }
        
        if(!AliastoDeleteId.isEmpty()){
         	AliasToDelete = [SELECT Id 
                             FROM Distributor_Alias__c 
                             WHERE id in :AliastoDeleteId];
            Delete AliasToDelete;
        }
        
        if(!AliasToAdd.isEmpty()){
            try{
                insert AliasToAdd;
            }catch(DMLException e){
                System.debug(e);
            }
        }
    }
    else{
        Set<String> keys = new Set<String>();
        Set<String> dupKeys = new Set<String>();
        for (Sales__c s : Trigger.new) {
            if(!keys.add(s.key__c.toLowerCase())){
               dupKeys.add(s.key__c.toLowerCase());
            }
        }
        if(!dupKeys.isEmpty()){//Duplicate alias
            for(String s : dupKeys){
            	keys.remove(s);
            }
        }
        List<Distributor_Alias__c> temp = [SELECT Distributor__c, Distributor__r.ownerid, key__c 
                                           FROM Distributor_Alias__c
                                           WHERE key__c in :keys];
        Map<String, Distributor_Alias__c> entries = new Map<String, Distributor_Alias__c> ();
        for(Distributor_Alias__c t : temp){ //Map keys
            for(String s : keys){
                if(t.key__c.equalsIgnoreCase(s)){
                    entries.put(s.toLowerCase(),t);   
                }
            }
        }
        Map <id, Account> ownerid = new Map <id, Account>([SELECT id, ownerid FROM Account WHERE recordtype.name = 'Distributor']);
        
        for(Sales__c s : Trigger.new){
            if(s.key__c != null){// If key is found
                if(entries.get(s.key__c.toLowerCase()) != null){
                    s.Distributor__c = entries.get(s.key__c.toLowerCase()).Distributor__c;
                    s.ownerid = ownerId.get(s.distributor__c).ownerid;
                }
            }
        }
    }
}