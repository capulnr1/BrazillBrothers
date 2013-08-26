/*
Controller to parse CSV file
05/20/13 RT@IC Created controller (Case 80143)
*/

public class importToolCtrl {
    public Blob contentFile { get; set; }
    public String nameFile { get; set; }
    public String profile { get; set; }
    public Account[] pAccts { get; set; }
    public String BatchNumber { get; set; }
    public Date importDate { get; set; }
    // Get all the existing profiles settings that have settings
    public List<SelectOption> getProfiles(){
        Set<id> ids = new Set<id>();
        Import_Profile__c[] temp = [SELECT Principal_Id__c 
                                    FROM Import_Profile__c];
        
        for(Import_Profile__c ip : temp){
            ids.add(ip.Principal_Id__c);       
        }
        
        pAccts = [SELECT id, name 
                  FROM Account 
                  WHERE Recordtype.name = 'Principal' AND id in :ids];
        
        if(pAccts.isEmpty())
            return null;
        
        pAccts.sort();
        
        List<SelectOption> options = new List<SelectOption>();
        for(Account a : pAccts){
            options.add(new SelectOption(a.id, a.name));
        }
        return options;
    }
    
    //
    public pageReference ParseData() {
        Integer RowstoSkip = 0;
        Boolean skip = false;
        Integer counter = 0;
        String type = 'Sales__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType salesSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = salesSchema.getDescribe().fields.getMap();
        Import_Profile__c[] ip = [SELECT CSV_Position__c, Field_Name__c, Principal_Id__c 
                                  FROM Import_Profile__c
                                  WHERE Principal_Id__c = :profile and Field_Name__c != 'startAtRow'];
        
        Import_Profile__c[] RowSkip = [SELECT CSV_Position__c, Field_Name__c, Principal_Id__c 
                                       FROM Import_Profile__c
                                       WHERE Principal_Id__c = :profile and Field_Name__c = 'startAtRow' and CSV_Position__c != null LIMIT 1];
        
        if(!RowSkip.isEmpty()){
            RowsToSkip = Integer.valueOf(RowSkip[0].CSV_Position__c); 
            RowsToSkip--;
            skip = true;
        }
        
        if(ip.isEmpty()){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error retrieving principal settings.');
            ApexPages.addMessage(myMsg);
            return null;   
        }
        
        List<List<String>> parsedCSV = new List<List<String>>();
        Sales__c[] salesToAdd = new List <Sales__c>();
        
        if (contentFile != null){
            Datetime currentDT = DateTime.now();
            BatchNumber = String.valueOf(currentDT);
            BatchNumber = BatchNumber.remove(' ');
            BatchNumber = BatchNumber.remove('-');
            BatchNumber = BatchNumber.remove(':');
            
            String fileString = contentFile.toString();
            parsedCSV = parseCSV(fileString, skip, RowsToSkip);
            map<String, Integer> temp;
            integer i = 0;
            for (List<String> row : parsedCSV){
                salesToAdd.add(new Sales__c());
                temp = mapColumns(row);
                for(Import_Profile__c p : ip){
                    if(String.ValueOf(fieldMap.get(p.Field_Name__c).getDescribe().getType()) == 'STRING' && p.Field_Name__c != null){
                        salesToAdd[i].put(p.Field_Name__c, row[convertLetterToNumber(p.CSV_Position__c)-1]);
                        salesToAdd[i].Principal__c = profile;
                        salesToAdd[i].Import_Batch__c = BatchNumber;
                        if(importDate != null)
                            salesToAdd[i].Trans_Date__c = importDate;
                    }
                    else if(String.ValueOf(fieldMap.get(p.Field_Name__c).getDescribe().getType()) == 'CURRENCY' && p.Field_Name__c != null){
                        String parseMoney = row[convertLetterToNumber(p.CSV_Position__c)-1];
                        if(parseMoney.containsAny('$')){
                            parseMoney = parseMoney.remove('$');
                            parseMoney = parseMoney.remove(',');
                            parseMoney = parseMoney.remove('\"');
                            if(parseMoney.containsAny('(') && parseMoney.containsAny(')'))
                                parseMoney = '-' + parseMoney;
                            parseMoney = parseMoney.remove('(');
                            parseMoney = parseMoney.remove(')');
                            parseMoney = parseMoney.replaceAll( '\\s+', '');
                        }
                        salesToAdd[i].put(p.Field_Name__c, Decimal.valueOf(parseMoney));
                        salesToAdd[i].Principal__c = profile;
                        salesToAdd[i].Import_Batch__c = BatchNumber;
                        if(importDate != null)
                            salesToAdd[i].Trans_Date__c = importDate;
                    }
                    else if(String.ValueOf(fieldMap.get(p.Field_Name__c).getDescribe().getType()) == 'DATE' && p.Field_Name__c != null){
                        salesToAdd[i].put(p.Field_Name__c, Date.valueOf(row[convertLetterToNumber(p.CSV_Position__c)-1]));
                        
                        salesToAdd[i].Principal__c = profile;
                        salesToAdd[i].Import_Batch__c = BatchNumber;
                        
                        if(importDate != null)
                            salesToAdd[i].Trans_Date__c = importDate;
                    }
                    else{
                        String fieldType = String.ValueOf(fieldMap.get(p.Field_Name__c).getDescribe().getType());
                        String fieldLabel = fieldMap.get(p.Field_Name__c).getDescribe().getLabel();
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Could not load CSV. Trying to load invalid data from column \"' + p.CSV_Position__c + '\" to \"' + fieldLabel + '\", which is of type \"' + fieldType + '\". Please check column sequence in import settings for selected profile.');
                        ApexPages.addMessage(myMsg);  
                        return null;
                    }
                }
                i++;
            }
            try{
                insert salesToAdd;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Successfully loaded sale\'s data. (Batch Code: ' + BatchNumber + ')');
                ApexPages.addMessage(myMsg);
                ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.INFO, 'URL to report: <a href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/00OZ0000000Oey9?pv0=' + BatchNumber + '">Click Here.</a>');
                ApexPages.addMessage(myMsg2);
                importDate = null;
            }catch(DMLException e){
                System.debug(e);
            }
        }
        return null;
    }
    
    //Convert column letter to number
    public Integer convertLetterToNumber(String letter){
        map<String, Integer> reference = new map<String, Integer>{'a' => 1, 'b' => 2,  'c' => 3, 'd' => 4, 'e' => 5, 'f' => 6, 'g' => 7, 'h' => 8, 'i' => 9, 'j' => 10, 'k' => 11, 'l' => 12, 'm' => 13, 'n' => 14, 'o' => 15, 'p' => 16, 'q' => 17, 'r' => 18, 's' => 19, 't' => 20, 'u' => 21, 'v' => 22, 'w' => 23, 'x' => 24, 'y' => 25, 'z' => 26};
            integer results = 0;
        Integer i=0;
        do{
            if(i<letter.length()){
                integer d = reference.get(letter.substring(i,i+1).toLowerCase()) - 1 + 1;
                results = 26 * results + d;
            }
            i++;
        }while(i < letter.length());
        return results;
    }
    
    /*
Credit to
http://wiki.developerforce.com/index.php/Code_Samples#Parse_a_CSV_with_APEX
*/
    public static List<List<String>> parseCSV(String contents, Boolean skipHeaders, Integer RowsToSkip) {
        List<List<String>> allFields = new List<List<String>>();
        
        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        //Remove "," from single cells
        contents = contents.replaceAlL(',",",',', ,');
        
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        contents = contents.replaceAll('""','DBLQT');
        
        
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
        List<String> lines = new List<String>();
        try {
            //lines = contents.split('\n'); //correction: this only accomodates windows files
            lines = contents.split('\r'); // using carriage return accomodates windows, unix, and mac files
            //http://www.maxi-pedia.com/Line+termination+line+feed+versus+carriage+return+0d0a
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        System.Debug('LINES'+lines);
        for(String line: lines) {
            // check for blank CSV lines (only commas)
            if (line.replaceAll(',','').trim().length() == 0) break;
            
            List<String> fields = line.split(','); 
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field: fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }                
            }
            allFields.add(cleanFields);
            
        }
        
        if (skipHeaders){
            for(integer i = 0; i < RowsToSkip; i++){
                allFields.remove(0);
                
                System.debug('$%^'+RowsToSkip);
            } 
        }
        return allFields;      
    }
    
    // Maps header values to the column number they are in
    //*bug if there is two of the same value in the row
    public map<String,Integer> mapColumns(list<String> fields) {
        map<String,Integer> columnMap = new map<String,Integer>{};
            integer size = fields.size();
        for (Integer i = 0; i < size; i++) {
            columnMap.put(String.ValueOf(fields[i]),i);
        }
        return columnMap;
    }
}