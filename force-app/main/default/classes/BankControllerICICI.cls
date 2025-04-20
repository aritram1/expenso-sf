public with sharing class BankControllerICICI {

    public static final String CLASS_NAME = 'BankControllerICICI';

    // This method enriches the sms record if it's from ICICI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static SMS__c processForICICIBankSA(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        
        try{
        
            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');
            
            // Savings account block
            // Credit
            if(sms.Content__c.toUpperCase().startsWith('DEAR CUSTOMER, ACCT XX360 IS CREDITED')){
                // Regex to extract the name
                Pattern nameRegex = Pattern.compile('Acct .* credited with Rs .* from ([\\w\\s]+)\\.');
                Matcher nameMatcher = nameRegex.matcher(sms.Content__c);
                if (nameMatcher.find()) {
                    String name = nameMatcher.group(1);
                    sms.beneficiary_name__c = Util.toCamelCase(name); // convert to camel case for better readability
                    System.debug('Extracted Name: ' + sms.beneficiary_name__c);
                }

                // Regex to extract the amount
                Pattern amountRegex = Pattern.compile('credited with Rs ([\\d\\.]+)');
                Matcher amountMatcher = amountRegex.matcher(sms.Content__c);
                if (amountMatcher.find()) {
                    String amount = amountMatcher.group(1);
                    sms.Amount__c = Decimal.valueOf(amount ?? '0');
                    System.debug('Extracted Amount: ' + sms.Amount__c);
                }
            }
            else if(sms.Content__c.toUpperCase().startsWith('ICICI BANK ACCOUNT XX360 CREDITED')){
                
                String amount =  contentArray[5].replace(',' , '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                if(sms.Content__c.contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                }
                else if(sms.Content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                }
                else if(sms.Content__c.contains('NEFT')){
                    sms.Payment_Via__c = 'NEFT';
                    String beneficiaryAndReferenceString = sms.Content__c.split('Info')[1].split('Available')[0].replace('.', '');
                    sms.Payment_Reference__c = beneficiaryAndReferenceString.split('-')[1];
                    sms.beneficiary_name__c = beneficiaryAndReferenceString.split('-')[2];
                    sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability

                    // if(sms.Content__c.contains('Available Balance is Rs.')){
                    //     String availableBalanceString = sms.Content__c.split('Available Balance is Rs.')[1];
                    //     sms.SA_available_balance__c = availableBalanceString.substring(0, availableBalanceString.length()-1).replace(',', '').trim();
                    // }
                }
            }
            // debit 1
            else if(sms.Content__c.toUpperCase().startsWith('ICICI Bank Acct XX360 debited with')){
                
                String amount =  contentArray[7].replace(',' , '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                if(sms.Content__c.contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                }
                if(sms.Content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = sms.Content__c.split('IMPS:')[1].split('. Call ')[0];
                    sms.beneficiary_name__c = sms.Content__c.split('credited.')[0].split('&')[1];
                    sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                }
                if(sms.Content__c.contains('RTGS')){
                    sms.Payment_Via__c = 'RTGS';
                }
            }
            // debit 2
            else if(sms.Content__c.toUpperCase().startsWith('ICICI Bank Acc XX360 debited Rs.')){
                
                // Fix some typo in SMS
                sms.Content__c = sms.Content__c.replace('Avb Bal Rs.', 'Avl Bal Rs.');
                sms.Content__c = sms.Content__c.replace('To dispute Call', 'To dispute call');
                String amount =  contentArray[6].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                String dateValue = contentArray[8];
                sms.beneficiary_name__c = sms.Content__c.split(dateValue)[1].split('Avl Bal')[0].trim();
                if(sms.beneficiary_name__c.endsWith('.')){
                    sms.beneficiary_name__c = sms.beneficiary_name__c.substring(0, sms.beneficiary_name__c.length()-1);
                }
            }
            // debit 3
            else if(sms.Content__c.toUpperCase().startsWith('ICICI Bank Acc XX360 is debited with')){
                String amount =  contentArray[8].replace(',' , '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c.split('. Available bal:')[0].split(' on ')[1].trim();
                sms.beneficiary_name__c = sms.beneficiary_name__c.substring(9, sms.beneficiary_name__c.length());
            }
            // debit 4 (ICICI bank latest message changes)
            else if(sms.Content__c.toUpperCase().startsWith('ICICI Bank Acct XX360 debited for')){
                
                // Regex to extract the full name
                Pattern nameRegex = Pattern.compile('; ([A-Za-z\\s]+) credited\\.');
                Matcher nameMatcher = nameRegex.matcher(sms.Content__c);
                if (nameMatcher.find()) {
                    String name = nameMatcher.group(1).trim();
                    sms.beneficiary_name__c = name;
                    System.debug('Extracted Name: ' + name);
                }

                // Regex to extract the amount
                Pattern amountRegex = Pattern.compile('debited for Rs ([\\d\\.]+)');
                Matcher amountMatcher = amountRegex.matcher(sms.Content__c);
                if (amountMatcher.find()) {
                    String amount = amountMatcher.group(1).trim();
                    sms.Amount__c = Decimal.valueOf(amount ?? '0');

                    System.debug('Extracted Amount: ' + amount);
                }
                if(sms.Content__c.toUpperCase().contains('UPI:')){
                    sms.Payment_Via__c = 'UPI';
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankAmazonCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
    // End method
    
    // Balance Update methods
    // To be merged with above methods as part of #optimization
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

    // Processes SMS for ICICI Bank Savings Account
    public static SMS__c processForICICIBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = new SMS__c();

        try { 
            if (sms.Content__c.toUpperCase().startsWith('ICICI Bank Account XX360 credited')){
                Pattern regex = Pattern.compile('Available Balance is Rs\\. ([\\d,]+\\.\\d{2})');
                Matcher matcher = regex.matcher(sms.Content__c);
                if (matcher.find()) {
                    String availableBalance = matcher.group(1);
                    smsOutput.SA_Available_Balance__c = availableBalance;
                    System.debug('Extracted Available Balance: ' + availableBalance);
                }
            } 
            else if (sms.Content__c.toUpperCase().startsWith('ICICI Bank Acct XX360 debited Rs.')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '');
            }
            else if(sms.Content__c.toUpperCase().startsWith('ICICI BANK ACC XX360 DEBITED RS.')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '').trim();
                if(smsOutput.SA_Available_Balance__c.endsWith('.')){
                    smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.substring(0, smsOutput.SA_Available_Balance__c.length()-1);
                } 
            }
            else if(sms.Content__c.toUpperCase().startsWith('ICICI Bank Acc XX360 is debited with')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('. Available bal: Rs. ')[1].split('. For dispute call')[0].replace(',','');
            }

            if(smsOutput.SA_Available_Balance__c.endsWith('.')){
                smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.substring(0, smsOutput.SA_Available_Balance__c.length() - 1);
            }
            smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.replace(',', '');

        } 
        catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForICICIBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return smsOutput;
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

                String amount =  inrValue.trim().replace(',', '');
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
    


}