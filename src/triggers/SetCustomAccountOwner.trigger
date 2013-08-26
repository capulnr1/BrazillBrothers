trigger SetCustomAccountOwner on Account (before insert, before update) {

    try{
        for(account a : Trigger.new){
            if(string.valueOf(a.OwnerId).startsWith('005'))
                a.Owner__c = a.OwnerId;
            else
                a.Owner__c = null; 
        }
    }
    catch(exception e){
        System.debug('@@@@ setCustomAccountOwner ~ ' + e);
    }

}