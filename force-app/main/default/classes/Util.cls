public class Util {

    public static final String CLASS_NAME = 'Util';
    public static final String SBI_SA_PATTERN = '.*(6414|a/cx6414|xx6414).*';
    public static final String ICICI_SA_PATTERN = '.*(xxx360|xx360|a/cx360).*';            
    public static final String HDFC_SA_PATTERN = '.*(9560|x9560|\\*9560|xxxx9560|hdfc bank a/c|7164).*';
    public static final String ICICI_CC_PATTERN = '.*(9006|x9006).*';
    public static final String ICICI_AMAZON_CC_PATTERN = '.*(7005|xx7005).*';
    public static final String HDFC_RUPAY_CC_PATTERN = '.*(2004|xx2004).*';
    
    public static String clipTo255char(String str){
        if(str == null) {
            return str;
        }
        return str.length() <= 255 ? str : str.substring(0, 255);
    }

    public static SMS__c populateTransactionDate(SMS__c sms){
        String receivedAt = sms.Received_At__c?.replace('T', ' ')?.split(' ')[0];
        if(receivedAt?.contains('-')){
            Integer yyyy = Integer.valueOf(receivedAt.split('-')[0]);
            Integer mm = Integer.valueOf(receivedAt.split('-')[1]);
            Integer dd = Integer.valueOf(receivedAt.split('-')[2]);
            sms.Transaction_Date__c = Date.newInstance(yyyy, mm, dd);
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
        System.debug('getAccounts=>' + smsList);
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

    // Get the list of all accounts
    public static Map<String, Finance_Account__c> getAllAccounts() {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<Finance_Account__c> allAccounts = [SELECT Id, External_Id__c FROM Finance_Account__c];
        for (Finance_Account__c fa : allAccounts) {
            allAccountsMap.put(fa.External_Id__c, fa);
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

    public static List<SMS__c> extractBeneficiaryAndAmountFromSMS(List<SMS__c> smsList, Map<String, Finance_Account__c> mapAccounts) {

        System.debug('extractBeneficiaryAndAmountFromSMS=>smsList: ' + smsList);

        List<SMS__c> result = new List<SMS__c>();

        try {
            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty() || mapAccounts == null || mapAccounts.isEmpty()) {
                return null;
            }

            for (SMS__c sms : smsList) {
                SMS__c processedSMS = new SMS__c();
                try{
                    String content = sms.Content__c != null ? sms.Content__c.toLowerCase() : '';
                    System.debug('mapAccounts=>' + mapAccounts);

                    if (Pattern.compile(SBI_SA_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerSBI.processForSBIBankSA(sms);
                    } 
                    else if (Pattern.compile(ICICI_SA_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerICICI.processForICICIBankSA(sms);
                    } 
                    else if (Pattern.compile(HDFC_SA_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerHDFC.processForHDFCBankSA(sms);
                    } 
                    else if (Pattern.compile(ICICI_CC_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerICICI.processForICICIBankCC(sms);
                    } 
                    else if (Pattern.compile(ICICI_AMAZON_CC_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerICICI.processForICICIBankAmazonCC(sms);
                    } 
                    else if (Pattern.compile(HDFC_RUPAY_CC_PATTERN).matcher(content).matches()) {
                        processedSMS = BankControllerHDFC.processForHDFCBankRupayCC(sms);
                    } 
                    else {
                        processedSMS = sms;
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

                String content = sms.Content__c != null ? sms.Content__c.toLowerCase() : '';
                
                SMS__c smsOutput = new SMS__c();

                try {

                    if (Pattern.compile(SBI_SA_PATTERN).matcher(content).matches()) {
                        smsOutput = BankControllerSBI.processForSBIBankSA_BalanceUpdate(sms);
                    } 
                    else if (Pattern.compile(ICICI_SA_PATTERN).matcher(content).matches()) {
                        smsOutput = BankControllerICICI.processForICICIBankSA_BalanceUpdate(sms);
                    } 
                    else if (Pattern.compile(HDFC_SA_PATTERN).matcher(content).matches()) {
                        smsOutput = BankControllerHDFC.processForHDFCBankSA_BalanceUpdate(sms);
                    } 
                    else if (Pattern.compile(ICICI_CC_PATTERN).matcher(content).matches()) {
                        smsOutput = BankControllerICICI.processForICICIBankCC_BalanceUpdate(sms);
                    } 
                    else if (Pattern.compile(ICICI_AMAZON_CC_PATTERN).matcher(content).matches()) {
                        smsOutput = BankControllerICICI.processForICICIBankAmazonCC_BalanceUpdate(sms);
                    } 
                    // else if (Pattern.compile(HDFC_RUPAY_CC_PATTERN).matcher(content).matches()) {
                    //     // TB Implemented
                    //     smsOutput = BankControllerHDFC.processForHDFCBankSA_BalanceUpdate(sms);
                    // } 
                    else {
                        smsOutput = sms;
                    }
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
    
    /**
     * Populates processed information for a list of SMS__c records.
     * 
     * @param smsRecords The list of SMS__c records to process.
     * @return The updated list of SMS__c records with processed information.
     */
    public static List<SMS__c> populateProcessedInfo(List<SMS__c> smsRecords){
        for(SMS__c sms : smsRecords){
            if(sms.CC_Available_Balance__c != null || sms.SA_Available_Balance__c != null){
                sms.Account_Balance_Processed__c = true;
            }
            if(sms.Amount__c != null){
                sms.Amount_Processed__c = true;
            }
            if(sms.Beneficiary__c != null){
                sms.Beneficiary_Processed__c = true;
            }
            if(sms.Payment_Reference__c != null || sms.Payment_Via__c != null){
                sms.Payment_Info_Processed__c = true;
            }
            // Not required now : Since client is already sending the date in payload
            // sms = Util.populateTransactionDate(sms);
        }
        return smsRecords;
	}

    /**
     * This method generates a 6-digit numeric OTP for the provided email address.
     * 
     * @param email The email address for which the OTP is being generated.
     * @return The generated OTP as a String.
     */
    public static String generateOTP(String providedEmail){

        String otp = '';
        
        List<OTP__c> otpRecords = [
                                    SELECT Id, Email__c, Phone__c, OTP__c, IsValid__c 
                                    FROM OTP__c 
                                    WHERE Email__c = :providedEmail 
                                    AND IsValid__c = true 
                                    ORDER BY CreatedDate DESC //  DESC 
                                    LIMIT 1];
        
        if (!otpRecords.isEmpty()) {
            otp = otpRecords[0].OTP__c;
        }
        else{
            // Create an OTP__c record
            OTP__c otpRecord = new OTP__c();
            otpRecord.Email__c = providedEmail;
            otpRecord.OTP__c = String.valueOf(Math.round(Math.random() * 900000 + 100000));
            insert otpRecord;
            otp = otpRecord.OTP__c;
        }
        return otp;
    }

    /**
     * Verifies if the provided OTP matches the expected OTP for the given email address.
     *
     * @param providedEmail The email address for which the OTP is being verified.
     * @param providedOTP The OTP provided by the user for verification.
     * @return A boolean value indicating whether the provided OTP is valid (true) or not (false).
     */
    public static boolean checkOTP(String providedEmail, String providedOTP){

        boolean result = false;

        try{
            if(String.isEmpty(providedEmail) || String.isEmpty(providedOTP)){
                throw new FinPlanException('Email and OTP are required for verification');
            }
            
            // Query the OTP__c object to get the OTP for the given email
            List<OTP__c> otpRecords = [
                                        SELECT Id, Email__c, Phone__c, OTP__c, IsValid__c, Used__c, Used_At__c
                                        FROM OTP__c 
                                        WHERE Email__c = :providedEmail 
                                        AND IsValid__c = true 
                                        ORDER BY CreatedDate DESC //  DESC 
                                        LIMIT 1];
            
            if (!otpRecords.isEmpty()) {
                String presentOTP = otpRecords[0].OTP__c;
                if(presentOTP == providedOTP){
                    otpRecords[0].Used__c = true;
                    otpRecords[0].Used_At__c = Datetime.now();
                    update otpRecords[0];
                    result = true;
                }
            }
        }
        catch (Exception e) {
            System.debug('Failed to check the otp: ' + e.getMessage());
            throw new FinPlanException('Failed to check the OTP. Please try again later.');
        }

        return result;
    }

    // The email is being sent from flow

    /**
     * Helper method to send an email
     * @param email The recipient's email address
     * @param otp The OTP to send
     */
    // public static void sendEmail(String email, String otp, DateTime expirationTime) {
    public static void sendEmail(String email, String otp) {
        System.debug('Inside the send email method');
        System.debug('Email: ' + email);
        System.debug('OTP: ' + otp);
        try {
            // Create the email body
            // String emailBody = 'The OTP is ' + otp + ' and it is valid until ' + expirationTime.format('yyyy-MM-dd HH:mm:ss') + '.';
            String emailBody = 'The OTP is ' + otp + ' and it is valid for next 5 minutes.'; 

            // Create a single email message
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setToAddresses(new String[] { email });
            emailMessage.setSubject('Your OTP Code');
            emailMessage.setPlainTextBody(emailBody);

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });

            System.debug('Email sent successfully to ' + email + ' with OTP: ' + otp);
        } 
        catch (Exception e) {
            System.debug('Failed to send email to ' + email + ': ' + e.getMessage());
            throw new FinPlanException('Failed to send email. Please try again later.');
        }
    }

    public static boolean invalidateOTP(String email, String otp){
        boolean otpInvalidated = false;
        try {
            // Query the OTP__c object to get the OTP for the given email
            List<OTP__c> otpRecords = [
                                        SELECT Id, Used__c, Used_At__c, OTP__c 
                                        FROM OTP__c 
                                        WHERE Email__c = :email 
                                        AND OTP__c = :otp
                                        ORDER BY CreatedDate DESC //  DESC 
                                        LIMIT 1];
            if (!otpRecords.isEmpty()) {
                OTP__c otpRecord = otpRecords[0];
                otpRecord.Used__c = true;
                otpRecord.Used_At__c = Datetime.now();
                update otpRecord;
                otpInvalidated = true;
            }
            return otpInvalidated;
        }
        catch (Exception e) {
            System.debug('Failed to invalidate the otp: ' + e.getMessage());
            throw new FinPlanException('Failed to invalidate the OTP. Please try again later.');
        }
    }

    /**
     * Populates Finance Account information for a list of SMS__c records.
     * 
     * @param smsRecords The list of SMS__c records to process.
     * @return The updated list of SMS__c records with finance account information.
     */
    public static List<SMS__c> populateFinanceAccountFromSMS(List<SMS__c> smsRecords, Map<String, Finance_Account__c> mapAccounts) {
        
        for (SMS__c sms : smsRecords) {
            
            if(sms.External_Id__c == null){
                sms.External_Id__c = sms.Received_At__c.replaceAll('[^0-9]', '');
            }
            
            String content = sms.Content__c != null ? sms.Content__c.toLowerCase() : '';
            
            System.debug('mapAccounts=>' + mapAccounts);

            if (Pattern.compile(SBI_SA_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('SBI-SA') != null ? mapAccounts.get('SBI-SA').Id : null;
            } 
            else if (Pattern.compile(ICICI_SA_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('ICICI-SA') != null ? mapAccounts.get('ICICI-SA').Id : null;
            } 
            else if (Pattern.compile(HDFC_SA_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('HDFC-SA') != null ? mapAccounts.get('HDFC-SA').Id : null;
            } 
            else if (Pattern.compile(ICICI_CC_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('ICICI-CC') != null ? mapAccounts.get('ICICI-CC').Id : null;
            } 
            else if (Pattern.compile(ICICI_AMAZON_CC_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('ICICI-AMAZON-CC') != null ? mapAccounts.get('ICICI-AMAZON-CC').Id : null;
            } 
            else if (Pattern.compile(HDFC_RUPAY_CC_PATTERN).matcher(content).matches()) {
                sms.Finance_Account__c = mapAccounts.get('HDFC-RUPAY-CC') != null ? mapAccounts.get('HDFC-RUPAY-CC').Id : null;
            } 
            else {
                sms.Finance_Account__c = null; // Unknown account
            }
            System.debug('Content=>' + content);
            System.debug('Finance Account Id=>' + sms.Finance_Account__c);

        }
        return smsRecords;
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