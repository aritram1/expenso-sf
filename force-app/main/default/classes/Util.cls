public with sharing class Util {

    public static final String CLASS_NAME = 'Util';
    
    public static String clipTo255char(String str){
        if(str == null) {
            return str;
        }
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
                    if (GlobalConstants.ALL_CAPS_NAMES.contains(word.toUpperCase())){ // Do not convert the bank names to camel case as they are named in the system
                        modifiedWords.add(word.toUpperCase());
                        continue;
                    }
                    String firstAlphabet = word.substring(0, 1).toUpperCase();
                    String rest = word.substring(1, word.length()).toLowerCase();
                    modifiedWords.add(firstAlphabet + rest);
                }
            }

            // Join the words back together
            return String.join(modifiedWords, ' ');
            
        }
    }

    // Get the list of accounts from the list of SMS__c records
    public static Map<String, Finance_Account__c> getAccounts(List<SMS__c> smsList) {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<String> allAccountIds = new List<String>();
        for (SMS__c sms : smsList) {
            if (sms.Finance_Account__c != null) {
                allAccountIds.add(sms.Finance_Account__c);
            }
        }
        List<Finance_Account__c> allAccounts = [SELECT Id, Name FROM Finance_Account__c WHERE Id IN :allAccountIds];
        for (Finance_Account__c fa : allAccounts) {
            allAccountsMap.put(fa.Id, fa);
        }
        return allAccountsMap;
    }

    public static String sanitizeNumber(String str){
        String strUpperCase = str.toUpperCase().trim();
        strUpperCase = strUpperCase
                        .replace('INR', '')
                        .replace('RS', '')
                        .replace(',', '')
                        .trim();
        if(strUpperCase.endsWith('.')){
            strUpperCase = strUpperCase.substring(0, strUpperCase.length()-1);
        }
        if(strUpperCase.startsWith('.')){
            strUpperCase = strUpperCase.substring(1, strUpperCase.length());
        }
        return strUpperCase;
    }

    public static List<SMS__c> extractBeneficiaryAndAmountFromSMS(List<SMS__c> smsList) {

        List<SMS__c> result = new List<SMS__c>();

        try {
            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            Map<String, Finance_Account__c> mapAccounts = Util.getAccounts(smsList);

            for (SMS__c sms : smsList) {
                String accountName = mapAccounts.get(sms.Finance_Account__c).Name.toUpperCase();
                SMS__c processedSMS = new SMS__c();

                try{
                    if (accountName == 'HDFC SA') {
                        processedSMS = SMSProcessor.processForHDFCBankSA(sms);
                    } else if (accountName == 'ICICI SA') {
                        processedSMS = SMSProcessor.processForICICIBankSA(sms);
                    } else if (accountName == 'SBI SA') {
                        processedSMS = SMSProcessor.processForSBIBankSA(sms);
                    } else if (accountName == 'ICICI CC') {
                        processedSMS = SMSProcessor.processForICICIBankCC(sms);
                    } else if (accountName == 'ICICI AMAZON CC') {
                        processedSMS = SMSProcessor.processForICICIBankAmazonCC(sms);
                    } else if (accountName == 'HDFC Rupay CC') {
                        processedSMS = SMSProcessor.processForHDFCBankRupayCC(sms);
                    } else if (accountName == 'Amazon Wallet') {
                        processedSMS = SMSProcessor.processForAmazonWallet(sms);
                    }
                    // To be implemented, if required
                    // else if(accountName == 'Kuvera'){
                    //     processedSMS = SMSProcessor.processFor***(sms);
                    // }
                    // else if(accountName == 'Coin'){
                    //     processedSMS = SMSProcessor.processFor***(sms);
                    // }
                    // else if(accountName == 'Zerodha'){
                    //     processedSMS = SMSProcessor.processFor***(sms);
                    // }
                    // else if(accountName == 'Smallcase'){
                    //     processedSMS = SMSProcessor.processFor***(sms);
                    // }

                    // Fix the minor name differences for beneficiaries
                    // This method does not have any DML, so we can use it within a loop
                    processedSMS = BeneficiaryHandler.fixBeneficiaryName(processedSMS);

                    result.add(processedSMS);
                }
                catch (Exception e) {
                    FinPlanLogger.logError(CLASS_NAME, 'extractBeneficiaryAndAmountFromSMS', e, sms); // the last parameter is the entity Id, which is not available outside the loop
                }
            }

            // Also update the beneficiary Name with beneficiary Id
            // This method contains a DML so we may have to use it outside the loop
            result = BeneficiaryHandler.updateBeneficiary(result);

        } 
        catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBeneficiaryAndAmountFromSMS', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return result;
    }

    public static List<SMS__c> extractBalanceInfo(List<SMS__c> smsList) {

        List<SMS__c> outputList = new List<SMS__c>();

        try {
            Map<String, Finance_Account__c> mapAccounts = Util.getAccounts(smsList);

            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            for (SMS__c sms : smsList) {
                String accountNameInUpperCase = mapAccounts.get(sms.Finance_Account__c).Name.toUpperCase();
                SMS__c smsOutput = new SMS__c();

                try {
                    switch on accountNameInUpperCase {
                        when 'HDFC SA' {
                            smsOutput = SMSProcessor.processForHDFCBankSA_BalanceUpdate(sms);
                        }
                        when 'ICICI SA' {
                            smsOutput = SMSProcessor.processForICICIBankSA_BalanceUpdate(sms);
                        }
                        when 'SBI SA' {
                            smsOutput = SMSProcessor.processForSBIBankSA_BalanceUpdate(sms);
                        }
                        when 'ICICI CC' {
                            smsOutput = SMSProcessor.processForICICIBankCC_BalanceUpdate(sms);
                        }
                        when 'ICICI AMAZON CC' {
                            smsOutput = SMSProcessor.processForICICIBankAmazonCC_BalanceUpdate(sms);
                        }
                        // To be implemented, if required
                        // when 'KUVERA' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'COIN' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'ZERODHA' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                        // when 'SMALLCASE' {
                        //     smsOutput = SMSProcessor.SMSProcessor.processFor***_BalanceUpdate(sms);
                        // }
                    }
                }
                catch(Exception e){
                    FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, sms); 
                }
                outputList.add(smsOutput);
            }

        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return outputList;
    }
    
    // // Utility method : Clone a record of Transaction_Platform_Event__e
    // public static Transaction_Platform_Event__e cloneTransactionPE(Transaction_Platform_Event__e source) {
    //     // Create a new writable instance of the platform event
    //     Transaction_Platform_Event__e target = new Transaction_Platform_Event__e();

    //     // Explicitly copy fields
    //     target.Balance_Update__c = source.Balance_Update__c;
    //     target.External_Id__c = source.External_Id__c;
    //     target.Finance_Account__c = source.Finance_Account__c;
    //     target.SMS_Content__c = source.SMS_Content__c;
    //     target.SMS_Id__c = source.SMS_Id__c;
    //     target.Transaction_Date__c = source.Transaction_Date__c;
    //     target.Type__c = source.Type__c;

    //     return target;
    // }

    // // Method to convert from SMS__c to Transaction_Platform_Event__e
    // public static List<Transaction_Platform_Event__e> convertToTransactionPE(List<SMS__c> smsList) {
    //     List<Transaction_Platform_Event__e> transactionPEList = new List<Transaction_Platform_Event__e>();
        
    //     for (SMS__c sms : smsList) {
    //         Transaction_Platform_Event__e txnPE = new Transaction_Platform_Event__e(
    //             SMS_Content__c = sms.Content__c
    //         );
    //         transactionPEList.add(txnPE);
    //     }
    //     return transactionPEList;
    // }

    // // Method to convert from Transaction_Platform_Event__e to SMS_Platform_Event__e
    // public static List<SMS__c> convertToSMSList(List<Transaction_Platform_Event__e> transactionPEList) {
        
    //     List<SMS__c> smsList = new List<SMS__c>();
        
    //     for (Transaction_Platform_Event__e txnPE : transactionPEList) {
    //         SMS__c sms = new SMS__c(
    //             Amount__c = Decimal.valueof(txnPE.Amount__c),
    //             Payment_Via__c = txnPE.Payment_Via__c,
    //             beneficiary_name__c = txnPE.beneficiary_name__c,
    //             Payment_Reference__c = txnPE.Payment_Reference__c,
    //             Transaction_Date__c = txnPE.Transaction_Date__c

    //             // Content__c = txnPE.SMS_Content__c,
    //             // Sender__c = txnPE.Sender__c,
    //             // Received_At__c = txnPE.Received_At__c,
    //             // Finance_Account__c = txnPE.Finance_Account__c,
    //             // External_Id__c = txnPE.External_Id__c,
    //             // Device__c = txnPE.Device__c,
    //             // Transaction_Date__c = txnPE.Transaction_Date__c,
    //             // SMS_Id__c = txnPE.SMS_Id__c,
    //             // Type__c = txnPE.Type__c,
    //             // Balance_Update__c = txnPE.Balance_Update__c
    //         );
    //         smsList.add(sms);
    //     }
    //     return smsList;
    // }
     
}