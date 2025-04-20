public with sharing class BankControllerHDFC {

    public static final String CLASS_NAME = 'BankControllerHDFC';

        // This method enriches the sms record if it's from HDFC
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static SMS__c processForHDFCBankSA(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS);     
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');

            // credit 1
            if(sms.Content__c.contains('deposited')){
                String amount =  contentArray[2].replace(',' , '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                if(sms.Content__c.contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                    String str = sms.Content__c.split('for')[1].split('.Avl bal')[0];
                    sms.beneficiary_name__c = str.split('-')[1] + '-' + str.split('-')[2] + '-' + str.split('-')[3];
                    sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                    sms.Payment_Reference__c = str.split('-')[4];
                }
                else{
                    sms.beneficiary_name__c = sms.Content__c.split('for')[1].split('.Avl bal')[0];
                    if(sms.beneficiary_name__c.contains('-TPT-')){
                        sms.beneficiary_name__c = sms.beneficiary_name__c.split('-')[3];
                    }
                    sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                    if(sms.beneficiary_name__c.toUpperCase().contains('IMPS') && sms.beneficiary_name__c.contains('-')){
                        sms.Payment_Via__c = 'IMPS';
                        sms.Payment_Reference__c = sms.beneficiary_name__c.split('-')[1];
                    }
                    if(sms.beneficiary_name__c.toUpperCase().contains('NEFT') && sms.beneficiary_name__c.contains('-')){
                        sms.Payment_Via__c = 'NEFT';
                        integer lastIndexOfDash = sms.beneficiary_name__c.split('-').size() - 1;
                        sms.Payment_Reference__c = sms.beneficiary_name__c.split('-')[lastIndexOfDash];
                    }
                }
                
            }
            // credit 2
            else if(sms.Content__c.startsWith('Money Received')){
                String amount =  contentArray[4].replace(',' , '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');

                String str = sms.Content__c.split('Avl bal: INR')[0].split('by')[1].replace('(', '').replace(')', '');
                
                sms.beneficiary_name__c = str.split('IMPS Ref No. ')[0];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                
                if(sms.Content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = str.split('IMPS Ref No. ')[1];
                }
            }
            // credit 3
            else if(sms.Content__c.startsWith('HDFC Bank: Rs.') && sms.Content__c.contains('credited to a/c XXXXXX9560') && sms.Content__c.contains('UPI Ref No')){
                String amount =  contentArray[3].replace(',' , '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                String upiRef = sms.Content__c.split('UPI Ref No')[1];
                sms.Payment_Reference__c = upiRef.substring(0, upiRef.length()-2);
                sms.Payment_Via__c = 'UPI';
                String beneficiary = sms.Content__c.split(' by ')[1].split('UPI Ref No')[0];
                sms.beneficiary_name__c = beneficiary.substring(0, beneficiary.length()-2);
            }
            // credit 4 
            else if(sms.Content__c.contains('credited to HDFC Bank A/c xx9560')){

                String content = sms.Content__c;

                Pattern amountRegex = Pattern.compile('Rs\\.([\\d,]+(?:\\.\\d{1,2})?)');
                Pattern beneficiaryRegex = Pattern.compile('VPA\\s([\\w@.]+)');
                Pattern upiReferenceRegex = Pattern.compile('UPI\\s([\\d]+)');

                // Match amount
                Matcher amountMatcher = amountRegex.matcher(content);
                String amount = '';
                if (amountMatcher.find()) {
                    amount = amountMatcher.group(1);
                }
                sms.amount__c = Decimal.valueOf(amount ?? '0');


                // Match beneficiary
                Matcher beneficiaryMatcher = beneficiaryRegex.matcher(content);
                String beneficiary = '';
                if (beneficiaryMatcher.find()) {
                    beneficiary = beneficiaryMatcher.group(1);
                }
                sms.beneficiary_name__c = beneficiary;


                // Match Reference Number
                Matcher referenceMatcher = upiReferenceRegex.matcher(content);
                String referenceNumber = '';
                if (referenceMatcher.find()) {
                    referenceNumber = referenceMatcher.group(1);
                }
                sms.Payment_Via__c = 'UPI';
                sms.Payment_Reference__c = referenceNumber;
            }
            // debit1 bank transfer
            else if(sms.Content__c.contains('debited from a/c **9560') && sms.Content__c.contains('UPI')){
                String amount =  contentArray[3].replace(',' , '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'UPI';
                String content = sms.Content__c.replace('(', '').replace(')', '');
                sms.beneficiary_name__c = content.split(' to ')[1].split('. Not you?')[0].split('UPI Ref')[0];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability

                String paymentReferenceString = sms.Content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                sms.Payment_Reference__c = paymentReferenceString.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('UPI Ref No ', '').replace('UPI Ref No. ', '').trim();
            }
            // debit2 UPI
            else if(sms.Content__c.startswith('Money Transfer:Rs') && sms.Content__c.contains('UPI')){
                String amount =  contentArray[2].replace(',' , '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'UPI';
                sms.Payment_Reference__c = sms.Content__c.split(' UPI:')[1].split('Not you?')[0];
                sms.beneficiary_name__c = sms.Content__c.split(' UPI')[0].split(' to ')[1];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit3 UPI where sms starts like 
            // UPDATE: ....
            else if(sms.Content__c.contains('debited from HDFC Bank XX9560')){
                String amount =  contentArray[2].replace(',', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'UPI';
                sms.beneficiary_name__c = sms.Content__c.split('Info: UPI-')[1].split('Avl bal:INR')[0];
                if(sms.beneficiary_name__c.length() > 255){
                    sms.beneficiary_name__c = sms.beneficiary_name__c.substring(0,255);
                }
                integer countOfDash = sms.beneficiary_name__c.split('-').size();
                if(countOfDash > 2){ // meaning the it contains reference number etc along with beneficiary name
                    integer indexOfPaymentReference = countOfDash - 2;
                    sms.Payment_Reference__c = sms.beneficiary_name__c.split('-')[indexOfPaymentReference];
                }
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                
            }
            // debit3.1 UPI where sms starts like 
            else if(sms.Content__c.contains('debited from HDFC Bank A/c **9560')){
                
                String content = sms.Content__c;
                
                // Regular expressions
                String amountPattern = 'Rs\\.\\s*([\\d.,]+)';
                String toInfoPattern = 'to\\s+(A/c\\s+\\*\\*\\d+)';
                String refNoPattern = 'Ref No\\s+(\\d+)';

                // Extract amount
                Pattern amountRegex = Pattern.compile(amountPattern);
                Matcher amountMatcher = amountRegex.matcher(content);
                String amount = amountMatcher.find() ? amountMatcher.group(1) : null;

                // Extract 'To' information
                Pattern toInfoRegex = Pattern.compile(toInfoPattern);
                Matcher toInfoMatcher = toInfoRegex.matcher(content);
                String toInfo = toInfoMatcher.find() ? toInfoMatcher.group(1) : null;

                // Extract reference number
                Pattern refNoRegex = Pattern.compile(refNoPattern);
                Matcher refNoMatcher = refNoRegex.matcher(content);
                String refNo = refNoMatcher.find() ? refNoMatcher.group(1) : null;

                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Beneficiary_Name__c = Util.toCamelCase(toInfo);
                sms.Payment_Reference__c = refNo;
                sms.Payment_Via__c = 'UPI';
        
            }
            // debit4 via NEFT/IMPS 
            // where sms starts like "Thanks for paying ..."
            else if(sms.Content__c.startswith('Thanks for paying Rs.')){
                String amount =  contentArray[3].replace(',', '').replace('Rs.', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.Payment_Via__c = 'IMPS';
                sms.beneficiary_name__c = sms.Content__c.split('from A/c XXXX9560 to')[1].split('via HDFC Bank NetBanking')[0];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 5
            // where sms starts like "Alert!..."
            else if(sms.Content__c.startswith('Alert!') && sms.Content__c.contains('spent Rs')){
                String amount =  contentArray[2].replace(',', '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.Payment_Via__c = 'DEBITCARD';
                sms.beneficiary_name__c = sms.Content__c.split('At ')[1].split('On ')[0].replace('.', ' ').replace('_', '').trim();
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 6
            // where sms starts like "Money Transferred!..."
            else if(sms.Content__c.startsWith('Money Transferred - ')){
                String amount =  contentArray[4].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                // sms.SA_available_balance__c = sms.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
                // sms.type__c = 'Debit';
                String content = sms.Content__c.replace('(', 'STARTBRACKET').replace(')', 'ENDBRACKET').replace('.', '');
                sms.beneficiary_name__c = content.split(' to ')[1].split('STARTBRACKET')[0].trim();
                if(sms.Content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    if(content.contains('IMPS Ref No')){
                        sms.Payment_Reference__c = content.split('STARTBRACKETIMPS Ref No')[1].split('ENDBRACKET Avl bal:')[0];
                    }
                }
            }
            // debit 7
            // where sms starts like "Amt Sent Rs...."
            else if(sms.Content__c.startsWith('Amt Sent Rs.')){
                
                // Extra 2 steps since specifically these messages are using new line within them. 
                // So that needs to be replaced with a space for better handling
                sms.Content__c = sms.Content__c.replace('\n', ' '); 
                contentArray = sms.Content__c.split(' ');
                
                String amount =  contentArray[2].replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = sms.Content__c.split(' To ')[1].split(' On ')[0].trim();
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c);
                sms.Payment_Via__c = 'UPI';
                sms.Payment_Reference__c = sms.Content__c.split('Ref ')[1].split('Not You')[0].trim();
            }
            else if(sms.Content__c.startsWith('Sent Rs.')){

                // Regex to extract the beneficiary name
                Pattern nameRegex = Pattern.compile('To ([\\w\\s]+) On');
                Matcher nameMatcher = nameRegex.matcher(sms.Content__c);
                if (nameMatcher.find()) {
                    String name = nameMatcher.group(1).trim(); // Extract and trim the name
                    sms.Beneficiary_Name__c = Util.toCamelCase(name); // Convert to camel case for better readability
                    System.debug('Extracted Name: ' + sms.Beneficiary_Name__c);
                }

                // Regex to extract the amount
                Pattern amountRegex = Pattern.compile('Sent Rs\\.([\\d\\.]+)');
                Matcher amountMatcher = amountRegex.matcher(sms.Content__c);
                if (amountMatcher.find()) {
                    String amount = amountMatcher.group(1).trim(); // Extract and trim the amount
                    sms.Amount__c =  Decimal.valueOf(amount ?? '0');
                    System.debug('Extracted Amount: ' + sms.Amount__c);
                }

                // Regex to extract the reference number
                Pattern refRegex = Pattern.compile('Ref ([\\d]+)');
                Matcher refMatcher = refRegex.matcher(sms.Content__c);
                if (refMatcher.find()) {
                    String reference = refMatcher.group(1).trim(); // Extract and trim the reference number
                    sms.Payment_Reference__c = reference;
                    sms.Payment_Via__c = 'UPI';
                    System.debug('Extracted Reference Number: ' + sms.Payment_Reference__c);
                }

            }

            // debit 8 - ATM withdrawal
            else if(sms.Content__c.contains('withdrawn from')){
                
                String content = sms.Content__c;
                
                String amountPattern = 'Rs\\.([\\d]+)'; // Matches "Rs." followed by digits (the amount)
                String toInfoPattern = 'at\\s+(.+?)\\s+on'; // Matches text after "at" and before "on"
                String avlBalPattern = 'Avl bal:\\s*([\\d]+(?:\\.\\d{1,2})?)\\b'; // Matches "Avl bal:" followed by digits and decimal point

                // Extract amount
                Pattern amountRegex = Pattern.compile(amountPattern);
                Matcher amountMatcher = amountRegex.matcher(content);
                String amount = amountMatcher.find() ? amountMatcher.group(1) : null;
                amount = amount.replace(',', '');

                amount = sms.Content__c.split(' ')[0].replace('Rs.', '');

                // Extract 'To' information
                Pattern toInfoRegex = Pattern.compile(toInfoPattern);
                Matcher toInfoMatcher = toInfoRegex.matcher(content);
                String toInfo = toInfoMatcher.find() ? toInfoMatcher.group(1) : null;

                // Extract available balance
                Pattern avlBalRegex = Pattern.compile(avlBalPattern);
                Matcher avlBalMatcher = avlBalRegex.matcher(content);
                String avlBalance = avlBalMatcher.find() ? avlBalMatcher.group(1) : null;

                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = 'Self Transfer';
                sms.Payment_Via__c = 'ATM';
                sms.SA_Available_Balance__c = avlBalance;
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
    // End method

    // Processes SMS for HDFC Bank Savings Account
    public static SMS__c processForHDFCBankSA_BalanceUpdate(SMS__c sms) {

        SMS__c smsOutput = sms;

        boolean balaneUpdateRequired = 
            sms.Content__c.toUpperCase().contains('BALANCE') ||  
            sms.Content__c.toUpperCase().contains('BAL')
            ;
        
        if(balaneUpdateRequired == true){
            try {
                if (sms.Content__c.contains('deposited')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
                } 
                else if (sms.Content__c.startsWith('Money Received')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal: INR')[1];
                } 
                else if (sms.Content__c.contains('debited from HDFC Bank XX9560')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal:INR ')[1].replace(',', '');
                } 
                else if (sms.Content__c.startsWith('Money Transferred - ')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
                } 
                else if (sms.Content__c.contains('spent Rs')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
                } 
                else if (sms.Content__c.startsWith('Available Bal in HDFC Bank A/c XX9560')) {
                    smsOutput.SA_Available_Balance__c = sms.Content__c.split('INR ')[1].split('Cheques')[0];
                    smsOutput.SA_Available_Balance__c = Util.sanitizeNumber(smsOutput.SA_Available_Balance__c);
                } 
                else if(sms.Content__c.startswith('Alert!') && sms.Content__c.contains('spent Rs')){
                    smsOutput.SA_Available_Balance__c = smsOutput.Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
                } 
                else if(smsOutput.Content__c.startsWith('Money Transferred - ')){
                    smsOutput.SA_available_balance__c = smsOutput.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
                }
            } 
            catch (Exception e) {
                FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForHDFCBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
            }
        }

        return smsOutput;
    }

    public static SMS__c processForHDFCBankRupayCC(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS);     
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');

            // debit 1
            if(sms.Content__c.contains('On HDFC Bank Card 2004')){
                String amount =  contentArray[1]?.replace('Rs.', '')?.replace(' ', '')?.replace(',', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c?.split('At')[1]?.split('by')?.get(0);
                sms.Payment_Reference__c = sms.Content__c.toUpperCase()?.split('AT')[1]?.split('BY')[1]?.replace('UPI', '');
                if(sms.Content__c.toUpperCase().contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankRupayCC', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
}