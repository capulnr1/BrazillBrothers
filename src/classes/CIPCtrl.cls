/*
    Custom Data Loader with configurable settings.
    05/20/13 RT@IC Created controller (Case 80143)
*/

public class CIPCtrl{ 
    public List<csWrapper> settingList{get; set;}
    public String profile { get; set; }
    public Integer state { get; set; }
    public Account[] pAccts { get; set; }
    public Import_Profile__c start { get; set;} //REMOVE AFTER
    //public Import_Profile__c importDate { get; set; } //remove after
    
    //Constructor
    public CIPCtrl() {
        pAccts = [SELECT id, name 
                  FROM Account 
                  WHERE Recordtype.name = 'Principal'];
        if(!pAccts.isEmpty()){
            pAccts.sort();
            profile = pAccts[0].id;
        }
        getSettings();
    }
    
    // Get all the existing profiles
    public List<SelectOption> getProfiles(){
        if(pAccts.isEmpty())
            return null;
        
        List<SelectOption> options = new List<SelectOption>();
        for(Account a : pAccts){
            options.add(new SelectOption(a.id, a.name));
        }

        return options;
    }
    
    //Clear and populate custom settings with Sales field and labels
    public pageReference clear(){
        settingList = new List<csWrapper>();
        Integer counter = 0;
        String type='Sales__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType salesSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = salesSchema.getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable() == true && String.ValueOf(fieldMap.get(fieldName).getDescribe().getType()) != 'REFERENCE'){
                System.debug('##Field API Name='+fieldName);// list of all field API name
                fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
                
                //if(fieldMap.get(fieldName).getDescribe().getLabel() != 'startAtRow') //REMOVE THIS AFTER THE DEMO
                    settingList.add(new csWrapper(new Import_Profile__c(name = counter++ + ' - ' + profile, 
                                                                        Field_Name__c = fieldname, 
                                                                        Principal_Id__c = profile), fieldMap.get(fieldName).getDescribe().getLabel() + ' (' + String.ValueOf(fieldMap.get(fieldName).getDescribe().getType()).toLowerCase() +')'));
            }
        }
        
        start = new Import_Profile__C(name = profile + String.valueof(date.today()), Field_name__c = 'startAtRow', Principal_Id__c = profile); // REMOVE AFTER
        //importDate = new Import_Profile__C(name = profile + String.valueof(date.today()), Field_name__c = 'importDate', Principal_Id__c = profile); // REMOVE AFTER
            
        return null;
    }
    
    //Remove fields from the custom setting that are no longer on the sales object or has been modified
    public pageReference updateSettings(){
        Import_Profile__c[] temp = [SELECT id, Field_Name__c, CSV_Position__c
                                    FROM Import_Profile__c 
                                    WHERE Principal_Id__c = :Profile];
        
        Import_Profile__c[] deleteSettings = new List<Import_Profile__c>();
        
        String deletedFields = '';
        String type='Sales__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType salesSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = salesSchema.getDescribe().fields.getMap();            
        for(Import_Profile__c t : temp){
            if(fieldMap.get(t.Field_Name__c) == null && t.Field_Name__c != 'startAtRow'){ // && t.Field_Name__c != 'importDate'){
                deleteSettings.add(t); 
                deletedFields += t.Field_Name__c + ', ';
            }
        }
        if(!deleteSettings.isEmpty()){
            try{
                delete deleteSettings;
                deletedFields = deletedFields.removeEnd(', ');
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'The following fields has been removed from the Sales object: ' + deletedFields);
                ApexPages.addMessage(myMsg);
            }catch(DMLException e){
                System.debug(e); 
            }
        }

        return null;  
    }
    
    //Remove custom settings with no CSV entries
    public pageReference removeBlankSettings(){
        Import_Profile__c[] temp = [SELECT id, Field_Name__c, CSV_Position__c
                                    FROM Import_Profile__c 
                                    WHERE Principal_Id__c = :Profile];
        
        Import_Profile__c[] deleteSettings = new List<Import_Profile__c>();
        for(Import_Profile__c t : temp){
            if(t.CSV_Position__c == null){
                deleteSettings.add(t);   
            }
        }
        
        if(!deleteSettings.isEmpty()){
            try{
                delete deleteSettings;   
            }catch(DMLException e){
                System.debug(e); 
            }
        }
        return null;   
    }
    
    //Merge blank custom settings with existing ones in the profile
    public pageReference getSettings(){
        clear();
        updateSettings();
        
        Import_Profile__c[] temp = [SELECT id, Field_Name__c, CSV_Position__c
                                    FROM Import_Profile__c 
                                    WHERE Principal_Id__c = :Profile];
        
        if(!temp.isEmpty()){
            for(Import_Profile__c t : temp){
                for(csWrapper cs : settingList){
                    if(cs.ip.Field_Name__c == t.Field_Name__c){
                        cs.ip = t;
                    }
  
                }
                if(t.field_name__c == 'startAtRow')
                {
                    start = t;   
                }
                /*if(t.field_name__c == 'importDate')
                {
                    importDate = t;
                }*/
            }
        }                  
        return null;
    }
    
    //Check for duplicate column letters in the custom setting
    public boolean dupCheck(){
        set<string> uniqueSet = new Set<String>{};
        for(csWrapper cs : settingList){
            if(cs.ip.CSV_Position__c != null){
                if(!uniqueSet.add(cs.ip.CSV_Position__c)){
                    return false;
                }
            }
        }
        return true;
    }
    
    //Update or create new profile settings
    public boolean save2(){
        Import_Profile__c[] temp = new List<Import_Profile__c>();
        for(csWrapper cs : settingList){
            //if(cs.ip.CSV_Position__c != null)
                temp.add(cs.ip);
        }  

        if(!dupCheck()){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'One or more inputs have the same columns');
            ApexPages.addMessage(myMsg);
            return false; 
        }
        
        /*
        if((temp[0].Qty__c == null || temp[0].Unit_Price__c == null) && temp[0].Total__c == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Total is required if Qty or Unit Price is blank.');
            ApexPages.addMessage(myMsg);
            return false;
        }
        if(temp[0].Qty__c == null && temp[0].Unit_Price__c == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Qty or Unit Price is required');
            ApexPages.addMessage(myMsg);
            return false;
        }
        if(temp[0].Comm_Rate__c == null && temp[0].Comm_Amount__c == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Need at least Commission Amount or Rate filled-in.');
            ApexPages.addMessage(myMsg);
            return false;
        }
        */
        
        try{
            upsert temp;
            upsert start;
            removeBlankSettings();
            getSettings();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Successfully saved profile.');
            ApexPages.addMessage(myMsg);
            return true;
        }catch(DMLException e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error saving profile.');
            ApexPages.addMessage(myMsg);
            System.debug(e);
            return false;
        }
        return false;
    }
    
    //Save Button
    public pageReference save(){
        save2();   
        return null;
    }
    
    //Delete profile settings
    public void deleteProfile(){
        Import_Profile__c[] temp = [SELECT id 
                                    FROM Import_Profile__c 
                                    WHERE Principal_Id__c = :profile];

        try{
            delete temp;
            clear();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Successfully deleted profile.');
            ApexPages.addMessage(myMsg);
            
        }catch(DMLException e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error deleting profile.');
            ApexPages.addMessage(myMsg);
            System.debug(e);
        }
    }
    
    // Wrapper class to add labels and fields together
    public class csWrapper{
        public Import_Profile__c ip{get;set;}
        public String label{get;set;}

        public csWrapper(Import_Profile__c c, String fName){
            ip = c;
            label = fName;
        }
    } 
}