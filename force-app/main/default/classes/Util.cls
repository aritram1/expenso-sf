public with sharing class Util {
    
    public static String clipTo255char(String str){
        return str.length() <= 255 ? str : str.substring(0, 255);
    }

    public static SMS__c populateTransactionDate(SMS__c sms){
        String rawDateString = sms.Received_At__c?.split(' ')[0];
        if(rawDateString?.contains('-')){
            Integer yyyy = Integer.valueOf(rawDateString.split('-')[0]);
            Integer mm = Integer.valueOf(rawDateString.split('-')[1]);
            Integer dd = Integer.valueOf(rawDateString.split('-')[2]);
            sms.Transaction_Date__c = Date.newInstance(yyyy, mm, dd);
        }
        else{ 
            // Convert String -> Long -> DateTime -> Date
            sms.Transaction_Date__c = Date.valueOf(DateTime.newInstance(Long.valueOf(rawDateString))); 
        }
        return sms;
    }

    public static String toCamelCase(String inputString) {
        if(inputString == null){
            return inputString;
        }
        else{
            List<String> modifiedWords = new List<String>();
            inputString = inputString.trim();

            // Split the string into words
            List<String> words = inputString.trim().split(' ');
            
            for (String word : words) {
                word = word.trim(); // trim the whitespaces
                if(word.length() == 1){
                    modifiedWords.add(word.toUpperCase());  // if there is only one character in the word
                }
                else if(word.length() > 1){ // if there are atleast 2 characters in a word
                    String firstAlphabet = word.substring(0, 1).toUpperCase();
                    String rest = word.substring(1, word.length()).toLowerCase();
                    modifiedWords.add(firstAlphabet + rest);
                }
            }

            // Join the words back together
            return String.join(modifiedWords, ' ');
            
        }
    }


    // Utility method : Clone a record of Transaction_Platform_Event__e
    public static Transaction_Platform_Event__e cloneTransactionPE(Transaction_Platform_Event__e source) {
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e target = new Transaction_Platform_Event__e();

        // Explicitly copy fields
        target.Balance_Update__c = source.Balance_Update__c;
        target.External_Id__c = source.External_Id__c;
        target.Finance_Account__c = source.Finance_Account__c;
        target.SMS_Content__c = source.SMS_Content__c;
        target.SMS_Id__c = source.SMS_Id__c;
        target.Transaction_Date__c = source.Transaction_Date__c;
        target.Type__c = source.Type__c;

        return target;
    }

    // Method to convert from SMS__c to Transaction_Platform_Event__e
    public static List<Transaction_Platform_Event__e> convertToTransactionPE(List<SMS__c> smsList) {
        List<Transaction_Platform_Event__e> transactionPEList = new List<Transaction_Platform_Event__e>();
        
        for (SMS__c sms : smsList) {
            Transaction_Platform_Event__e txnPE = new Transaction_Platform_Event__e(
                SMS_Content__c = sms.Content__c
            );
            transactionPEList.add(txnPE);
        }
        return transactionPEList;
    }

    // Method to convert from Transaction_Platform_Event__e to SMS_Platform_Event__e
    public static List<SMS__c> convertToSMSList(List<Transaction_Platform_Event__e> transactionPEList) {
        
        List<SMS__c> smsList = new List<SMS__c>();
        
        for (Transaction_Platform_Event__e txnPE : transactionPEList) {
            SMS__c sms = new SMS__c(
                Amount__c = Decimal.valueof(txnPE.Amount__c),
                Payment_Via__c = txnPE.Payment_Via__c,
                beneficiary_name__c = txnPE.beneficiary_name__c,
                Payment_Reference__c = txnPE.Payment_Reference__c,
                Transaction_Date__c = txnPE.Transaction_Date__c

                // Content__c = txnPE.SMS_Content__c,
                // Sender__c = txnPE.Sender__c,
                // Received_At__c = txnPE.Received_At__c,
                // Finance_Account__c = txnPE.Finance_Account__c,
                // External_Id__c = txnPE.External_Id__c,
                // Device__c = txnPE.Device__c,
                // Transaction_Date__c = txnPE.Transaction_Date__c,
                // SMS_Id__c = txnPE.SMS_Id__c,
                // Type__c = txnPE.Type__c,
                // Balance_Update__c = txnPE.Balance_Update__c
            );
            smsList.add(sms);
        }
        return smsList;
    }
     
}