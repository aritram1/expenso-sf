public with sharing class SMSProcessor {

    public static final String CLASS_NAME = 'SMSProcessor';

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

    public static SMS__c processForHDFCBankRupayCC(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS);     
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');

            // debit 1
            if(sms.Content__c.contains('On HDFC Bank Card 2004')){
                String amount =  contentArray[1].replace('Rs.', '').replace(' ', '');
                sms.amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c.split('At')[1].split('by')[0];
                sms.Payment_Reference__c = sms.Content__c.toUpperCase().split('AT')[1].split('BY')[1].replace('UPI', '');
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

    public static SMS__c processForAmazonWallet(SMS__c inputSMS){
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        return sms;
    }

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

    // This method enriches the sms record if it's from SBI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static SMS__c processForSBIBankSA(SMS__c inputSMS){
        
        // Create a new writable instance of the platform event
        SMS__c sms = inputSMS.clone(false, true); // Util.cloneTransactionPE(inputSMS); 
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = sms.Content__c?.split(' ');
            
            // credit 1
            if(sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')){
                String amount =  contentArray[9].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                String modifiedContent = sms.Content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                sms.beneficiary_name__c = modifiedContent.split('by')[2].split('START_BRACKET')[0];
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                if(modifiedContent.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = modifiedContent.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('IMPS Ref no', '').trim();
                }
            }
            // credit 2
            else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit')){
                String amount =  sms.Content__c.split('of Rs ')[1].split(' on ')[0].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                if(sms.Content__c.contains('IMPS')) { 
                    sms.Payment_Via__c = 'IMPS'; 
                }
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[0].split('has credit for')[1];
            }
            // credit 3
            else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit for')){
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[0].split('has credit for ')[1].trim();
                sms.beneficiary_name__c = sms.Content__c.split(' of Rs ')[1].split(' on ')[0].replace(',', '').trim();

            }
            // debit 1
            else if(sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')){
                String amount =  contentArray[9].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = sms.Content__c.split('and')[1].split('credited')[0].trim();
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 2
            else if(sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
                String amount =  contentArray[12].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = 'SBI Internal Transfer';
            }
            // debit via yono app
            else if(sms.Content__c.contains('Your A/C XXXXX816414 Debited INR')){
                String amount =  contentArray[5].replace(',', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.beneficiary_name__c = sms.Content__c.split('Avl Balance INR')[0].split('Transferred to')[1].trim();
                if(sms.beneficiary_name__c.endsWith('.')){
                    sms.beneficiary_name__c = sms.beneficiary_name__c.substring(0, sms.beneficiary_name__c.length()-1);
                }
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                sms.Payment_Via__c = 'IMPS';
            }
            // atm withdrawal
            else if(sms.Content__c.contains('withdrawn at SBI ATM')){
                String amount =  contentArray[3].replace(',' , '').replace('Rs.', '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');

                sms.Payment_Via__c = 'ATM';
                sms.beneficiary_name__c = 'SBI ATM withdrawal';
                sms.beneficiary_name__c = Util.toCamelCase(sms.beneficiary_name__c); // convert to camel case for better readability
                sms.Payment_Reference__c = contentArray[15];
                if(sms.Payment_Reference__c.endsWith('.')){
                    sms.Payment_Reference__c = sms.Payment_Reference__c.substring(0, sms.Payment_Reference__c.length()-1);
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError(CLASS_NAME, 'processForHDFCBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }
        return sms;
    }
    // End method

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
            if(sms.Content__c.startsWith('Dear Customer, Acct XX360 is credited')){
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
            else if(sms.Content__c.startsWith('ICICI Bank Account XX360 credited')){
                
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
            else if(sms.Content__c.startsWith('ICICI Bank Acct XX360 debited with')){
                
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
            else if(sms.Content__c.startsWith('ICICI Bank Acc XX360 debited Rs.')){
                
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
            else if(sms.Content__c.startsWith('ICICI Bank Acc XX360 is debited with')){
                String amount =  contentArray[8].replace(',' , '');
                sms.Amount__c = Decimal.valueOf(amount ?? '0');
                sms.beneficiary_name__c = sms.Content__c.split('. Available bal:')[0].split(' on ')[1].trim();
                sms.beneficiary_name__c = sms.beneficiary_name__c.substring(9, sms.beneficiary_name__c.length());
            }
            // debit 4 (ICICI bank latest message changes)
            else if(sms.Content__c.startsWith('ICICI Bank Acct XX360 debited for')){
                
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

    // Processes SMS for HDFC Bank Savings Account
    public static SMS__c processForHDFCBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms.Content__c.contains('deposited')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
            } else if (sms.Content__c.startsWith('Money Received')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal: INR')[1];
            } else if (sms.Content__c.contains('debited from HDFC Bank XX9560')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal:INR ')[1].replace(',', '');
            } else if (sms.Content__c.startsWith('Money Transferred - ')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
            } else if (sms.Content__c.contains('spent Rs')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
            } else if (sms.Content__c.startsWith('Available Bal in HDFC Bank A/c XX9560')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('INR ')[1].split('Cheques')[0];
                smsOutput.SA_Available_Balance__c = Util.sanitizeNumber(smsOutput.SA_Available_Balance__c);
            } 
            else if(sms.Content__c.startswith('Alert!') && sms.Content__c.contains('spent Rs')){
                smsOutput.SA_Available_Balance__c = smsOutput.Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
            } 
            else if(smsOutput.Content__c.startsWith('Money Transferred - ')){
                smsOutput.SA_available_balance__c = smsOutput.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForHDFCBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
        }

        return smsOutput;
    }

    // Processes SMS for SBI Bank Savings Account
    public static SMS__c processForSBIBankSA_BalanceUpdate(SMS__c sms) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if (sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if(sms.Content__c.startsWith('Your A/C XXXXX816414 has credit')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',' ,'');
            } else if(sms.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if(sms.Content__c.contains('Your A/C XXXXX816414 Debited INR')){
                smsOutput.SA_available_balance__c = sms.Content__c.split('Avl Balance INR')[1].split('-')[0].replace(',', '');

            } else if(sms.Content__c.contains('withdrawn at SBI ATM')){
                smsOutput.SA_available_balance__c = sms.Content__c.split(' ')[18].replace('Rs.', '');
                if(smsOutput.SA_available_balance__c.endsWith('.')){
                    smsOutput.SA_available_balance__c = smsOutput.SA_available_balance__c.substring(0, smsOutput.SA_available_balance__c.length()-1);
                }
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForSBIBankSA', e, null); // the last parameter is the entity Id, which is not available outside the loop
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
            if (sms.Content__c.startsWith('ICICI Bank Account XX360 credited')){
                Pattern regex = Pattern.compile('Available Balance is Rs\\. ([\\d,]+\\.\\d{2})');
                Matcher matcher = regex.matcher(sms.Content__c);
                if (matcher.find()) {
                    String availableBalance = matcher.group(1);
                    smsOutput.SA_Available_Balance__c = availableBalance;
                    System.debug('Extracted Available Balance: ' + availableBalance);
                }
            } 
            else if (sms.Content__c.startsWith('ICICI Bank Acct XX360 debited Rs.')) {
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '');
            }
            else if(sms.Content__c.startsWith('ICICI Bank Acc XX360 debited Rs.')){
                smsOutput.SA_Available_Balance__c = sms.Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '').trim();
                if(smsOutput.SA_Available_Balance__c.endsWith('.')){
                    smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.substring(0, smsOutput.SA_Available_Balance__c.length()-1);
                } 
            }
            else if(sms.Content__c.startsWith('ICICI Bank Acc XX360 is debited with')){
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

}