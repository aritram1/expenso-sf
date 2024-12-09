public with sharing class SMSHandlerBank {

    public static Transaction_Platform_Event__e processForICICIBankAmazonCC(Transaction_Platform_Event__e txnPE1){
       
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1); 
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = txnPE.SMS_Content__c?.split(' ');

            // debit 1
            if(txnPE.SMS_Content__c.contains('spent using ICICI Bank Card XX7005')){
                txnPE.amount__c = contentArray[1];
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('on')[2].split('Avl Limit')[0];
                txnPE.CC_Available_Balance__c = txnPE.SMS_Content__c.split('Avl Limit: INR')[1].split('If not you')[0];
                txnPE.CC_Available_Balance__c = txnPE.CC_Available_Balance__c.replace(' ', '').replace('INR', '').replace(',', '');
                if(txnPE.CC_Available_Balance__c.endsWith('.')){
                    txnPE.CC_Available_Balance__c = txnPE.CC_Available_Balance__c.substring(0, txnPE.CC_Available_Balance__c.length()-1);
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError('processForICICIBankAmazonCC', e);
        }

        return txnPE;
    }

    public static Transaction_Platform_Event__e processForHDFCBankRupayCC(Transaction_Platform_Event__e txnPE1){
        
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1);    
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = txnPE.SMS_Content__c?.split(' ');

            // debit 1
            if(txnPE.SMS_Content__c.contains('On HDFC Bank Card 2004')){
                txnPE.amount__c = contentArray[1].replace('Rs.', '').replace(' ', '');
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('At')[1].split('by')[0];
                txnPE.Payment_Reference__c = txnPE.SMS_Content__c.toUpperCase().split('AT')[1].split('BY')[1].replace('UPI', '');
                if(txnPE.SMS_Content__c.toUpperCase().contains('UPI')){
                    txnPE.Payment_Via__c = 'UPI';
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError('processForHDFCBankRupayCC', e);
        }
        return txnPE;
    }

    public static Transaction_Platform_Event__e processForAmazonWallet(Transaction_Platform_Event__e txnPE){
        return txnPE;
    }

    // This method enriches the sms record if it's from HDFC
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Transaction_Platform_Event__e processForHDFCBankSA(Transaction_Platform_Event__e txnPE1){
        
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1);    
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = txnPE.SMS_Content__c?.split(' ');

            // credit 1
            if(txnPE.SMS_Content__c.contains('deposited')){
                txnPE.amount__c = contentArray[2].replace(',' , '');
                // txnPE.type__c = 'Credit';
                txnPE.SA_available_balance__c = txnPE.SMS_Content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
                if(txnPE.SMS_Content__c.contains('UPI')){
                    txnPE.Payment_Via__c = 'UPI';
                    String str = txnPE.SMS_Content__c.split('for')[1].split('.Avl bal')[0];
                    txnPE.beneficiary_name__c = str.split('-')[1] + '-' + str.split('-')[2] + '-' + str.split('-')[3];
                    txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                    txnPE.Payment_Reference__c = str.split('-')[4];
                }
                else{
                    txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('for')[1].split('.Avl bal')[0];
                    if(txnPE.beneficiary_name__c.contains('-TPT-')){
                        txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.split('-')[3];
                    }
                    txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                    if(txnPE.beneficiary_name__c.toUpperCase().contains('IMPS') && txnPE.beneficiary_name__c.contains('-')){
                        txnPE.Payment_Via__c = 'IMPS';
                        txnPE.Payment_Reference__c = txnPE.beneficiary_name__c.split('-')[1];
                        // txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.split('-')[2];
                    }
                    if(txnPE.beneficiary_name__c.toUpperCase().contains('NEFT') && txnPE.beneficiary_name__c.contains('-')){
                        txnPE.Payment_Via__c = 'NEFT';
                        integer lastIndexOfDash = txnPE.beneficiary_name__c.split('-').size() - 1;
                        txnPE.Payment_Reference__c = txnPE.beneficiary_name__c.split('-')[lastIndexOfDash];
                        // txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.split('-')[2];
                    }
                }
                
            }
            // credit 2
            else if(txnPE.SMS_Content__c.startsWith('Money Received')){
                txnPE.amount__c = contentArray[4].replace(',' , '');
                txnPE.SA_available_balance__c = txnPE.SMS_Content__c.split('Avl bal: INR')[1];
                // txnPE.type__c = 'Credit';
                String str = txnPE.SMS_Content__c.split('Avl bal: INR')[0].split('by')[1].replace('(', '').replace(')', '');
                
                txnPE.beneficiary_name__c = str.split('IMPS Ref No. ')[0];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                
                if(txnPE.SMS_Content__c.contains('IMPS')){
                    txnPE.Payment_Via__c = 'IMPS';
                    txnPE.Payment_Reference__c = str.split('IMPS Ref No. ')[1];
                }
            }
            // credit 3
            else if(txnPE.SMS_Content__c.startsWith('HDFC Bank: Rs.') && txnPE.SMS_Content__c.contains('credited to a/c XXXXXX9560') && txnPE.SMS_Content__c.contains('UPI Ref No')){
                txnPE.amount__c = contentArray[3].replace(',' , '');
                String upiRef = txnPE.SMS_Content__c.split('UPI Ref No')[1];
                txnPE.Payment_Reference__c = upiRef.substring(0, upiRef.length()-2);
                txnPE.Payment_Via__c = 'UPI';
                String beneficiary = txnPE.SMS_Content__c.split(' by ')[1].split('UPI Ref No')[0];
                txnPE.beneficiary_name__c = beneficiary.substring(0, beneficiary.length()-2);
                // txnPE.type__c = 'Credit';
            }
            // debit1 bank transfer
            else if(txnPE.SMS_Content__c.contains('debited from a/c **9560') && txnPE.SMS_Content__c.contains('UPI')){
                txnPE.amount__c = contentArray[3].replace(',' , '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'UPI';
                String content = txnPE.SMS_Content__c.replace('(', '').replace(')', '');
                txnPE.beneficiary_name__c = content.split(' to ')[1].split('. Not you?')[0].split('UPI Ref')[0];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability

                String paymentReferenceString = txnPE.SMS_Content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                txnPE.Payment_Reference__c = paymentReferenceString.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('UPI Ref No ', '').replace('UPI Ref No. ', '').trim();
            }
            // debit2 UPI
            else if(txnPE.SMS_Content__c.startswith('Money Transfer:Rs') && txnPE.SMS_Content__c.contains('UPI')){
                txnPE.amount__c = contentArray[2].replace(',' , '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'UPI';
                txnPE.Payment_Reference__c = txnPE.SMS_Content__c.split(' UPI:')[1].split('Not you?')[0];
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' UPI')[0].split(' to ')[1];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit3 UPI where sms starts like 
            // UPDATE: ....
            else if(txnPE.SMS_Content__c.contains('debited from HDFC Bank XX9560')){
                txnPE.amount__c = contentArray[2].replace(',', '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'UPI';
                txnPE.SA_available_balance__c = txnPE.SMS_Content__c.split('Avl bal:INR ')[1].replace(',', '');
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('Info: UPI-')[1].split('Avl bal:INR')[0];
                if(txnPE.beneficiary_name__c.length() > 255){
                    txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.substring(0,255);
                }
                integer countOfDash = txnPE.beneficiary_name__c.split('-').size();
                if(countOfDash > 2){ // meaning the it contains reference number etc along with beneficiary name
                    integer indexOfPaymentReference = countOfDash - 2;
                    txnPE.Payment_Reference__c = txnPE.beneficiary_name__c.split('-')[indexOfPaymentReference];
                }
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                
            }
            // debit4 via NEFT/IMPS 
            // where sms starts like "Thanks for paying ..."
            else if(txnPE.SMS_Content__c.startswith('Thanks for paying Rs.')){
                txnPE.amount__c = contentArray[3].replace(',', '').replace('Rs.', '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'IMPS';
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('from A/c XXXX9560 to')[1].split('via HDFC Bank NetBanking')[0];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 5
            // where sms starts like "Alert!..."
            else if(txnPE.SMS_Content__c.startswith('Alert!') && txnPE.SMS_Content__c.contains('spent Rs')){
                txnPE.amount__c = contentArray[2].replace(',', '').replace('Rs.', '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'DEBITCARD';
                txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('At ')[1].split('On ')[0].replace('.', ' ').replace('_', '').trim();
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
            }
            // debit 6
            // where sms starts like "Money Transferred!..."
            else if(txnPE.SMS_Content__c.startsWith('Money Transferred - ')){
                txnPE.amount__c = contentArray[4].replace(',', '');
                txnPE.SA_available_balance__c = txnPE.SMS_Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
                // txnPE.type__c = 'Debit';
                String content = txnPE.SMS_Content__c.replace('(', 'STARTBRACKET').replace(')', 'ENDBRACKET').replace('.', '');
                txnPE.beneficiary_name__c = content.split(' to ')[1].split('STARTBRACKET')[0].trim();
                if(txnPE.SMS_Content__c.contains('IMPS')){
                    txnPE.Payment_Via__c = 'IMPS';
                    if(content.contains('IMPS Ref No')){
                        txnPE.Payment_Reference__c = content.split('STARTBRACKETIMPS Ref No')[1].split('ENDBRACKET Avl bal:')[0];
                    }
                }
            }
            // debit 7
            // where sms starts like "Amt Sent Rs...."
            else if(txnPE.SMS_Content__c.startsWith('Amt Sent Rs.')){
                
                // Extra 2 steps since specifically these messages are using new line within them. 
                // So that needs to be replaced with a space for better handling
                txnPE.SMS_Content__c = txnPE.SMS_Content__c.replace('\n', ' '); 
                contentArray = txnPE.SMS_Content__c.split(' ');
                
                txnPE.amount__c = contentArray[2].replace('Rs.', '');
                // txnPE.type__c = 'Debit';
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' To ')[1].split(' On ')[0].trim();
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c);
                txnPE.Payment_Via__c = 'UPI';
                txnPE.Payment_Reference__c = txnPE.SMS_Content__c.split('Ref ')[1].split('Not You')[0].trim();
            }
            // debit 8 - ATM withdrawal
            // where sms starts like "You've withdrawn Rs."
            else if(txnPE.SMS_Content__c.contains('ve withdrawn Rs.')){
                txnPE.amount__c = contentArray[2].replace(',' , '').replace('Rs.', '');
                // txnPE.type__c = 'Debit';
                txnPE.Payment_Via__c = 'ATM';
                txnPE.beneficiary_name__c = 'HDFC ATM withdrawal';
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c);
            }
            // balance update sms can start with two texts
            // 1 - 'Available Bal in HDFC Bank A/c XX9560 as on...'
            // 2 - 'Available Bal in HDFC Bank A/c XX9560 on...'
            else if(txnPE.SMS_Content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 as on')){
                txnPE.SA_available_balance__c = contentArray[12].substring(0, contentArray[12].length()-1);
                txnPE.SA_available_balance__c =  txnPE.SA_available_balance__c.replace('.Cheque', ''); // further check added
                // txnPE.type__c = 'balance_update';
            }
            else if(txnPE.SMS_Content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 on')){
                txnPE.SA_available_balance__c = contentArray[10].substring(0, contentArray[10].length()-1);
                txnPE.SA_available_balance__c =  txnPE.SA_available_balance__c.replace('.Cheque', ''); // further check added
                // txnPE.type__c = 'balance_update';
            }
        }
        catch(Exception e){
            FinPlanLogger.logError('processForHDFCBankSA', e);
        }
        return txnPE;
    }
    // End method

    // This method enriches the sms record if it's from SBI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Transaction_Platform_Event__e processForSBIBankSA(Transaction_Platform_Event__e txnPE1){
        
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1);
        
        try{

            List<String> contentArray = new List<String>();
            contentArray = txnPE.SMS_Content__c?.split(' ');
            
            // credit 1
            if(txnPE.SMS_Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')){
                txnPE.amount__c = contentArray[9].replace(',' , '').replace('Rs.', '');
                String modifiedContent = txnPE.SMS_Content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                txnPE.beneficiary_name__c = modifiedContent.split('by')[2].split('START_BRACKET')[0];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                if(modifiedContent.contains('IMPS')){
                    txnPE.Payment_Via__c = 'IMPS';
                    txnPE.Payment_Reference__c = modifiedContent.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('IMPS Ref no', '').trim();
                }
                // txnPE.type__c = 'Credit';
            }
            // credit 2
            else if(txnPE.SMS_Content__c.startsWith('Your A/C XXXXX816414 has credit')){
                txnPE.amount__c = txnPE.SMS_Content__c.split('of Rs ')[1].split(' on ')[0].replace(',', '');
                txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',' ,'');
                if(txnPE.SMS_Content__c.contains('IMPS')) { 
                    txnPE.Payment_Via__c = 'IMPS'; 
                }
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' of Rs ')[0].split('has credit for')[1];
                // txnPE.type__c = 'Credit';
            }
            // credit 3
            else if(txnPE.SMS_Content__c.startsWith('Your A/C XXXXX816414 has credit for')){
                // txnPE.type__c = 'Credit';
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' of Rs ')[0].split('has credit for ')[1].trim();
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' of Rs ')[1].split(' on ')[0].replace(',', '').trim();

            }
            // debit 1
            else if(txnPE.SMS_Content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')){
                txnPE.amount__c = contentArray[9].replace(',' , '').replace('Rs.', '');
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('and')[1].split('credited')[0].trim();
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                // txnPE.type__c = 'Debit';
            }
            // debit 2
            else if(txnPE.SMS_Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
                // txnPE.type__c = 'Debit';
                txnPE.amount__c = contentArray[12].replace(',', '');
                txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
                txnPE.beneficiary_name__c = 'SBI Internal Transfer';
            }
            // debit via yono app
            else if(txnPE.SMS_Content__c.contains('Your A/C XXXXX816414 Debited INR')){
                txnPE.amount__c = contentArray[5].replace(',', '');
                txnPE.SA_available_balance__c = txnPE.SMS_Content__c.split('Avl Balance INR')[1].split('-')[0].replace(',', '');
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('Avl Balance INR')[0].split('Transferred to')[1].trim();
                if(txnPE.beneficiary_name__c.endsWith('.')){
                    txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.substring(0, txnPE.beneficiary_name__c.length()-1);
                }
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                txnPE.Payment_Via__c = 'IMPS';
                // txnPE.type__c = 'Debit';
            }
            // atm withdrawal
            else if(txnPE.SMS_Content__c.contains('withdrawn at SBI ATM')){
                txnPE.amount__c = contentArray[3].replace(',' , '').replace('Rs.', '');
                txnPE.Payment_Via__c = 'ATM';
                // txnPE.type__c = 'Debit';
                
                txnPE.beneficiary_name__c = 'SBI ATM withdrawal';
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
                
                txnPE.SA_available_balance__c = contentArray[18].replace('Rs.', '');
                if(txnPE.SA_available_balance__c.endsWith('.')){
                    txnPE.SA_available_balance__c = txnPE.SA_available_balance__c.substring(0, txnPE.SA_available_balance__c.length()-1);
                }
                txnPE.Payment_Reference__c = contentArray[15];
                if(txnPE.Payment_Reference__c.endsWith('.')){
                    txnPE.Payment_Reference__c = txnPE.Payment_Reference__c.substring(0, txnPE.Payment_Reference__c.length()-1);
                }
            }
        }
        catch(Exception e){
            FinPlanLogger.logError('processForHDFCBankSA', e);
        }
        return txnPE;
    }
    // End method

    public static Transaction_Platform_Event__e processForICICIBankCC(Transaction_Platform_Event__e txnPE1){
        
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1);
        
        List<String> contentArray = new List<String>();
        contentArray = txnPE.SMS_Content__c?.split(' ');
        
        // Credit card blocks
        if(txnPE.SMS_Content__c.contains('spent on ICICI Bank Card XX9006')){
            
            // txnPE.type__c = 'Debit';
            txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(' at ')[1].split('. Avl Lmt')[0];
            txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
            txnPE.amount__c = contentArray[1].replace(',' , '');
            txnPE.CC_Available_Balance__c = txnPE.SMS_Content__c.split('Avl Lmt: INR')[1].split('. To dispute')[0];
        }
        return txnPE;
        
        // -- This part is not required since the bill paid sms is already tracked -- //
        // else if(txnPE.SMS_Content__c.contains('received on your ICICI Bank Credit Card Account 4xxx9006')){
        //     txnPE.Finance_Account__c = allBankAccountsMap.get('ICICI-CC').Id;
        //     txnPE.Balance_Update__c = true;
        //     // txnPE.type__c = 'balance_update';
        //     txnPE.amount__c = contentArray[5].replace(',' , '');
        //     txnPE.beneficiary_name__c = 'Payment Received ICICI CC';
        //     txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
        // }
    }
    

    // This method enriches the sms record if it's from ICICI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Transaction_Platform_Event__e processForICICIBankSA(Transaction_Platform_Event__e txnPE1){
        
        // Create a new writable instance of the platform event
        Transaction_Platform_Event__e txnPE = Util.clone(txnPE1);
        
        try{
        
        List<String> contentArray = new List<String>();
        contentArray = txnPE.SMS_Content__c?.split(' ');
        
        // Savings account block
        // Credit
        if(txnPE.SMS_Content__c.startsWith('ICICI Bank Account XX360 credited')){
            
            // txnPE.type__c = 'Credit';
            txnPE.amount__c = contentArray[5].replace(',' , '');
            if(txnPE.SMS_Content__c.contains('UPI')){
                txnPE.Payment_Via__c = 'UPI';
            }
            else if(txnPE.SMS_Content__c.contains('IMPS')){
                txnPE.Payment_Via__c = 'IMPS';
            }
            else if(txnPE.SMS_Content__c.contains('NEFT')){
                txnPE.Payment_Via__c = 'NEFT';
                String beneficiaryAndReferenceString = txnPE.SMS_Content__c.split('Info')[1].split('Available')[0].replace('.', '');
                txnPE.Payment_Reference__c = beneficiaryAndReferenceString.split('-')[1];
                txnPE.beneficiary_name__c = beneficiaryAndReferenceString.split('-')[2];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability

                if(txnPE.SMS_Content__c.contains('Available Balance is Rs.')){
                    String availableBalanceString = txnPE.SMS_Content__c.split('Available Balance is Rs.')[1];
                    txnPE.SA_available_balance__c = availableBalanceString.substring(0, availableBalanceString.length()-1).replace(',', '').trim();
                }
            }
        }
        // debit 1
        else if(txnPE.SMS_Content__c.startsWith('ICICI Bank Acct XX360 debited with')){
            
            // txnPE.type__c = 'Debit';
            txnPE.amount__c = contentArray[7].replace(',' , '');
            if(txnPE.SMS_Content__c.contains('UPI')){
                txnPE.Payment_Via__c = 'UPI';
            }
            if(txnPE.SMS_Content__c.contains('IMPS')){
                txnPE.Payment_Via__c = 'IMPS';
                txnPE.Payment_Reference__c = txnPE.SMS_Content__c.split('IMPS:')[1].split('. Call ')[0];
                txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('credited.')[0].split('&')[1];
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c); // convert to camel case for better readability
            }
            if(txnPE.SMS_Content__c.contains('RTGS')){
                txnPE.Payment_Via__c = 'RTGS';
            }
        }
        // debit 2
        else if(txnPE.SMS_Content__c.startsWith('ICICI Bank Acc XX360 debited Rs.')){
            
            // Fix some typo in SMS
            txnPE.SMS_Content__c = txnPE.SMS_Content__c.replace('Avb Bal Rs.', 'Avl Bal Rs.');
            txnPE.SMS_Content__c = txnPE.SMS_Content__c.replace('To dispute Call', 'To dispute call');
            
            
            // txnPE.type__c = 'Debit';
            txnPE.amount__c = contentArray[6].replace(',', '');
            txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '').trim();

            if(txnPE.SA_Available_Balance__c.endsWith('.')){
                txnPE.SA_Available_Balance__c = txnPE.SA_Available_Balance__c.substring(0, txnPE.SA_Available_Balance__c.length()-1);
            } 
            String dateValue = contentArray[8];
            txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(dateValue)[1].split('Avl Bal')[0].trim();
            if(txnPE.beneficiary_name__c.endsWith('.')){
                txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.substring(0, txnPE.beneficiary_name__c.length()-1);
            }
        }
        // debit 3
        else if(txnPE.SMS_Content__c.startsWith('ICICI Bank Acc XX360 is debited with')){
            
            txnPE.amount__c = contentArray[8].replace(',' , '');
            txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('. Available bal: Rs. ')[1].split('. For dispute call')[0].replace(',','');
            // txnPE.type__c = 'Debit';
            txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split('. Available bal:')[0].split(' on ')[1].trim();
            txnPE.beneficiary_name__c = txnPE.beneficiary_name__c.substring(9, txnPE.beneficiary_name__c.length());
        }
        // debit 4 (ICICI bank latest message changes)
        else if(txnPE.SMS_Content__c.startsWith('ICICI Bank Acct XX360 debited for')){
            
            txnPE.amount__c = contentArray[7].replace(',' , '');
            // txnPE.SA_Available_Balance__c = txnPE.SMS_Content__c.split('. Available bal: Rs. ')[1].split('. For dispute call')[0].replace(',','');
            if(txnPE.SMS_Content__c.toUpperCase().contains('UPI:')){
                txnPE.Payment_Via__c = 'UPI';
            }
            // txnPE.type__c = 'Debit';
            txnPE.beneficiary_name__c = txnPE.SMS_Content__c.split(';')[1].split('credited')[0].trim();
            if(String.isNotBlank(txnPE.beneficiary_name__c)){
                txnPE.beneficiary_name__c = Util.toCamelCase(txnPE.beneficiary_name__c);
            }
        }
    }
    catch(Exception e){
        FinPlanLogger.logError('processForICICIBankAmazonCC', e);
    }
        return txnPE;
    }
    // End method

}