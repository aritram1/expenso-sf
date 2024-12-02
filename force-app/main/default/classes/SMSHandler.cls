public with sharing class SMSHandler {

    static final String TAG = 'SMSHandler';

    static final Set<String> BANK_SMS_SENDERS = new Set<String>{'HDFC', 'ICICI', 'SBI'};
    static final Set<String> INVESTMENT_SMS_SENDERS = new Set<String>{'NPS', 'PPF', 'EPF'};
    static final String PPF_4DIGITS = '3962';

    public static List<SMS__c> processedMessages;
    public static List<SMS__c> lastBalanceUpdateSMSList;
    public static Map<String, Finance_Account__c> allBankAccountsMap = new Map<String, Finance_Account__c>();
    public static Map<String, Beneficiary__c> allBeneficiariesMap = new Map<String, Beneficiary__c>();
    public static Map<String, Investment__c> allInvestmentsMap = new Map<String, Investment__c>();
    
    public static Map<String, Finance_Account__c> lastBalanceBankAccountsMap = new Map<String, Finance_Account__c>();

    // Standard lists to do further actions
    public static List<SMS__c> listToCreateBankAccountTransacations = new List<SMS__c>();
    public static List<SMS__c> listToCreateInvestmentTransacations = new List<SMS__c>();
    public static List<SMS__c> listOfRejectedRecords = new List<SMS__c>();
    public static List<SMS__c> listOfAllowedRecords = new List<SMS__c>();
    
    public static void getAllBankAccountsAndBeneficiaries(){
        for(Finance_Account__c ba : [SELECT Id, Active__c, Account_Codes__c, 
                                         SA_Last_Balance__c, CC_Available_Limit__c, 
                                         CC_Max_Limit__c, Name FROM Finance_Account__c]){
            allBankAccountsMap.put(ba.Account_Codes__c, ba);
            lastBalanceBankAccountsMap.put(ba.id, ba);
        }

        // Get list of investments
        for(Investment__c inv : [SELECT Id, Name FROM Investment__c]){
            allInvestmentsMap.put(inv.Id, inv);
        }        

        // Get list of beneficiaries
        for(Beneficiary__c be : [SELECT Id, Name, Other_Names__c ,
                                                 Phone__c, Type__c, VPA__c,Display_Name__c,
                                                 External_Id__c
                                                 FROM Beneficiary__c]){
            allBeneficiariesMap.put(be.External_Id__c, be);
        }
    }

    // Method to enrich message data
    public static List<SMS__c> enrichData(List<SMS__c> allMessages){
        // initiate variables
        processedMessages = new List<SMS__c>();
        lastBalanceUpdateSMSList = new List<SMS__c>();
        getAllBankAccountsAndBeneficiaries();

        // The main loop starts
        for(SMS__c sms : allMessages){
            try{
                // set the date;
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

                // Personal
                if(sms.sender__c.startsWith('+')){  // set personal type
                    sms.type__c = 'personal';   
                }                
                // OTP
                else if (sms.content__c?.toUpperCase().contains('OTP') || sms.content__c?.toUpperCase().contains('VERIFICATION CODE')){
                    sms.Type__c = 'otp';
                }
                // Credit / Debit / Balance Update
                else{ 

                    // Case 1 : HDFC  SA
                    if(sms.Sender__c.contains('HDFC')){ // TBC Urgent Implementation  BANK_SMS_SENDERS.contains(sms.Sender__c)){
                        sms = FinplanSMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'HDFC-SA');
                    }
                    // Case 2 : ICICI SA
                    else if(sms.Sender__c.contains('ICICI')){
                        sms = FinplanSMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'ICICI-SA');
                    }
                    // Case 3 : SBI SA
                    else if(sms.Sender__c.contains('SBI') && !sms.content__c.contains(PPF_4DIGITS)){
                        sms = SMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'SBI-SA');
                    }
                    // Case 4 : SBI PPF
                    else if(sms.Sender__c.contains('SBI') && sms.content__c.contains(PPF_4DIGITS)){
                        // sms.Investment_Type__c = 'PPF';
                        // sms.Related_To_Investment__c = true;
                        sms = SMSHandlerInvestment.processForInvestments(sms, allInvestmentsMap, 'PPF');
                    }
                    // Case 5 : NPS
                    else if(sms.Sender__c.contains('NPS')){
                        // sms.Investment_Type__c = 'NPS';
                        // sms.Related_To_Investment__c = true;
                        sms = SMSHandlerInvestment.processForInvestments(sms, allInvestmentsMap, 'NPS'); 
                    }
                    // Other Types (like wallets for Amazon, Paytm, phonePe etc)
                    else{
                        sms = SMSHandlerOthers.processForOthers(sms, allBankAccountsMap);
                    }
                }
                
                ////////////////////////////////////////////////////////////////////////////////////////
                // Few final checks to classify messages further
                ////////////////////////////////////////////////////////////////////////////////////////
                
                // Check if this sms is related to credit / debit type transactions
                if(sms.amount_value__c != null && 
                    (sms.type__c.toUpperCase() == 'CREDIT' || sms.type__c.toUpperCase() == 'DEBIT'))
                {
                    sms.Create_Transaction__c = true;
                }

                // Check if this sms is related to updating balance at SA or CC
                if(String.isNotBlank(sms.CC_Available_Balance__c) || String.isNotBlank(sms.SA_available_balance__c)){
                    sms.Balance_Update__c = true;
                    lastBalanceUpdateSMSList.add(sms);
                }

                // If the type is still not assigned set type as promotional
                if(String.isBlank(sms.type__c)){
                    sms.type__c = 'promotional';
                }

                // Fix some specific beneficiary names to correct sms typos / provide better abbreviations
                if(sms.beneficiary__c != null){
                    sms = BeneficiaryHandler.fixBeneficiaryName(sms, allBeneficiariesMap);
                }
            }

            catch(Exception e){
                // throw e;
                // Get the detail error Info and Log the error
                String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
                String smsContent = sms.content__c + ' || Sender : ' + sms.sender__c + ' || Received At: ' + sms.Received_At__c;
                FinPlanLogger.logError(new FinPlanException(errorMessage), TAG, smsContent);
            }

            processedMessages.add(sms);
        
        }
        System.debug('Processed messages=>' + processedMessages);
        
        return processedMessages;
    }

    // This method updates the balance for savings account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String handleBankAccountBalanceUpdate(List<SMS__c> inputSMSList){

        System.debug('inputSMSList value inside handleBankAccountBalanceUpdate =>' + inputSMSList);
        System.debug('inputSMSList value inside handleBankAccountBalanceUpdate size =>' + inputSMSList.size());
        
        Boolean updateCCAccount = false;

        // The input list can contain more than one sms and we need the latest ones for each bank account
        Map<String, SMS__c> uniqueMap = new Map<String, SMS__c>();
        for(SMS__c message : inputSMSList){
            uniqueMap.put(message.finance_account__c, message);
        }
        List<SMS__c> uniqueSMSList = uniqueMap.values();

        System.debug('uniqueSMSList value inside handleBankAccountBalanceUpdate =>' + uniqueSMSList);
        System.debug('uniqueSMSList value inside handleBankAccountBalanceUpdate size =>' + uniqueSMSList.size());
        String balanceUpdateResponse = '';
        List<Finance_Account__c> toBeUpdatedBankAccounts = new List<Finance_Account__c>();
        try{
            for(SMS__c sms : uniqueSMSList){
                if(sms.finance_account__c != null){
                    Finance_Account__c ba = lastBalanceBankAccountsMap.get(sms.finance_account__c);
                    System.debug('sms=>' + sms);
                    
                    if(ba != null && ba.Account_Codes__c != null && ba.Account_Codes__c != ''){
                        if(ba.Account_Codes__c.endsWith('-SA')){ // Savings Account
                            System.debug('sms.SA_available_balance__c=>' + sms.SA_available_balance__c);
                            String availableSABalanceString = sms.SA_available_balance__c.replace(',', '');
                            availableSABalanceString = availableSABalanceString.endsWith('.') ? availableSABalanceString.substring(0, availableSABalanceString.length() - 1) : availableSABalanceString;
                            System.debug('Inside handleBankAccountBalanceUpdate for SA =>' + availableSABalanceString);                      
                            ba.SA_Last_Balance__c = Double.valueOf(availableSABalanceString);
                            
                            // In case this sms provides info on a credit card bill paid, 
                            // then bank account would be a savings account
                            // but we also need to update the CC account that the 
                            // bill is paid on this date, with this amount
                            // The flag is marked as true here.
                            if(sms.content__c.toUpperCase().contains('INFOBIL')){
                                updateCCAccount = true;
                            }
                        }
                        else if(ba.Account_Codes__c.endsWith('-CC')){   // Credit Card Account
                            String availableCCBalanceString = sms.CC_Available_Balance__c.replace(',', '');
                            System.debug('Inside handleBankAccountBalanceUpdate for CC =>' + availableCCBalanceString);                      
                            ba.CC_Available_Limit__c = Double.valueOf(availableCCBalanceString);
                        }
                        else if(ba.Account_Codes__c.endsWith('-WA')){   // Wallet Account (Like Amazon / Paytm etc)
                            String availableWABalanceString = sms.SA_available_balance__c.replace(',', '');
                            System.debug('Inside handleBankAccountBalanceUpdate for WA =>' + availableWABalanceString);                      
                            ba.SA_Last_Balance__c = Double.valueOf(availableWABalanceString);
                        }
                        toBeUpdatedBankAccounts.add(ba);
                        
                        // See above comment
                        // In case the sms is about paying a CC bill, then we need to specifically
                        // update the CC bank account with two information
                        // 1 - What is the amount paid (i.e.e CC_Last_Paid_Amount__c)
                        // 2 - When it was paid (i.e. CC_Last_Bill_Paid_Date__c)
                        if(updateCCAccount){
                            Finance_Account__c ccAccount = allBankAccountsMap.get('ICICI-CC');
                            ccAccount.CC_Last_Bill_Paid_Date__c = sms.Transaction_Date__c;
                            ccAccount.CC_Last_Paid_Amount__c = Double.valueOf(sms.Amount_Value__c);
                            toBeUpdatedBankAccounts.add(ccAccount);
                        }
                            
                        // For debug/response purpose, capture the updated balance and bank account name 
                        // to include the same in the API response
                        String resultText = 'Account Name : ' + ba.Name + ' Updated Balance : ' + sms.SA_available_balance__c + '. ';
                        balanceUpdateResponse = balanceUpdateResponse + resultText;
                    }
                }
            }
            if(toBeUpdatedBankAccounts.size() > 0){
                System.debug('toBeUpdatedBankAccounts inside SMSHandler.handleBankAccountBalanceUpdate =>' + toBeUpdatedBankAccounts);
                update toBeUpdatedBankAccounts;
            }
        }
        catch(Exception e){
            // Get the detail error Info and Log the error
            String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
            FinPlanLogger.logError(new FinPlanException(errorMessage), TAG);
            balanceUpdateResponse = 'Error occurred inside handleBankAccountBalanceUpdate : ' + errorMessage;
        }
        return balanceUpdateResponse;
    }
    // End method

}