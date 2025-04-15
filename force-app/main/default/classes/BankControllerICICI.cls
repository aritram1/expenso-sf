public with sharing class BankControllerICICI {

    public static final String CLASS_NAME = 'BankControllerICICI';

    public BankControllerICICI() {

    }

    // Process SMS for ICICI Savings Account
    public static SMS__c processForICICIBankSA(SMS__c inputSMS) {
        SMS__c sms = inputSMS.clone(false, true);
        try {
            List<String> contentArray = sms.Content__c?.split(' ');

            // Credit 1
            if (sms.Content__c.startsWith('ICICI Bank Account XX360 credited')) {
                String amount = contentArray[5].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'UPI';
                sms.beneficiary_name__c = Util.toCamelCase(sms.Content__c.split('Info')[1].split('Available')[0].trim());
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankSA', e, null);
        }
        return sms;
    }

    // Process SMS for ICICI Balance Update
    public static SMS__c processForICICIBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = sms.clone(false, true);
        try {
            if (sms.Content__c.startsWith('ICICI Bank Account XX360 credited')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Available Balance is Rs. ')[1].split('.')[0].replace(',', '');
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankSA_BalanceUpdate', e, null);
        }
        return smsOutput;
    }

    // Processes SMS for ICICI Bank Credit Card
    public static SMS__c processForICICIBankCC_BalanceUpdate(SMS__c sms) {
        
        SMS__c smsOutput = new SMS__c();

        try{
            if(sms.Content__c.contains('ICICI Bank Card XX9006')){
                Pattern inrRegex = Pattern.compile('INR ([\\d,]+\\.\\d{2})');
                // Pattern infoRegex = Pattern.compile('on (.*?)\\.');
                Matcher inrMatcher = inrRegex.matcher(sms.Content__c);
                List<String> inrValues = new List<String>();
                while (inrMatcher.find()) {
                    inrValues.add(inrMatcher.group(1).replace(',', '')); // Add each INR value to the list, replacing the comma
                }
                smsOutput.CC_Available_Balance__c = inrValues[1];
            }
        }
        catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return smsOutput;
    }

    // Processes SMS for ICICI Bank Amazon Credit Card
    public static SMS__c processForICICIBankAmazonCC_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms.Content__c.contains('spent using ICICI Bank Card XX7005')) {
                smsOutput.CC_Available_Balance__c = sms.Content__c.split('Avl Limit: INR')[1].split('If not you')[0];
                smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.replace(' ', '').replace('INR', '').replace(',', '');
                if (smsOutput.CC_Available_Balance__c.endsWith('.')) {
                    smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.substring(0, smsOutput.CC_Available_Balance__c.length() - 1);
                }
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankAmazonCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return smsOutput;
    }

    public static SMS__c processForICICIBankCC(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        
        List<String> contentArray = new List<String>();
        contentArray = sms.Content__c?.split(' ');
        
        // Credit card blocks
        if(sms.Content__c.contains('ICICI Bank Card XX9006')){

            Pattern inrRegex = Pattern.compile('INR ([\\d,]+\\.\\d{2})');
            Pattern beneficiaryNameRegex = Pattern.compile('(?:.*?)on .*? on (.*?)\\.');            
            
            // Update the amount
            List<String> inrValues = new List<String>();
            Matcher inrMatcher = inrRegex.matcher(sms.Content__c);
            while (inrMatcher.find()) {
                inrValues.add(inrMatcher.group(1).replace(',', '')); // Add each INR value to the list
            }
            String amount = inrValues[0];
            sms.Amount__c = Decimal.valueOf(amount ?? '0');
            
            Matcher infoMatcher = beneficiaryNameRegex.matcher(sms.Content__c);
            String info = '';
            if (infoMatcher.find()) {
                info = infoMatcher.group(1); // Extract the text between 'on' and '.'
            }
            sms.beneficiary_name__c = info;
        }
        return sms;
        
        // -- This part is not required since the bill paid sms is already tracked -- //
        // else if(sms.Content__c.contains('received on your ICICI Bank Credit Card Account 4xxx9006')){
        //     sms.Finance_Account__c = allBankAccountsMap.get('ICICI-CC').Id;
        //     sms.Balance_Update__c = true;
        //     // sms.type__c = 'balance_update';
        //     String amount =  contentArray[5].replace(',' , '');
        //     sms.beneficiary_name__c = 'Payment Received ICICI CC';
        //     sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
        // }
    }

    public static SMS__c processForICICIBankAmazonCC(SMS__c inputSMS){
       
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS);  
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');

            // debit 1
            if(sms.Content__c.contains('spent using ICICI Bank Card XX7005')){
                String amount =  contentArray[1].replace(',', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c.split('on')[2].split('Avl Limit')[0];
            }

            // credit 1
            // Payment received SMS
            else if(sms.Content__c.contains('received on your ICICI Bank Credit Card Account')){

                // Regex for INR value
                Pattern inrRegex = Pattern.compile('INR ([\\d,]+\\.\\d+)');

                // Match the INR value
                Matcher inrMatcher = inrRegex.matcher(sms.Content__c);
                String inrValue = '';

                if (inrMatcher.find()) {
                    inrValue = inrMatcher.group(1); // Extract the INR value
                }

                String amount =  inrValue;
                sms.amount__c = Decimal.valueOf(amount ?? '0');
            }

            // // credit 1
            // // Payment received SMS
            // else if(sms.Content__c.contains('(?=.*Payment)(?=.*received)(?=.*7005)')){
            //     // Regex for INR value
            //     Pattern inrRegex = Pattern.compile('INR ([\\d,]+\\.\\d+)');

            //     // Match the INR value
            //     Matcher inrMatcher = inrRegex.matcher(sms.Content__c);
            //     String inrValue = '';

            //     if (inrMatcher.find()) {
            //         inrValue = inrMatcher.group(1); // Extract the INR value
            //     }

            //     String amount =  inrValue;
            //     sms.amount__c = Decimal.valueOf(amount ?? '0');
            //     sms.Balance_Update__c = true;
            // }

        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankAmazonCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return sms;
    }
}