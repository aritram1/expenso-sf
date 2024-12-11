public with sharing class InvocableBalanceUpdateHandler {

    public static final String CLASS_NAME = 'InvocableBalanceUpdateHandler.';

    // Invocable method that Flow or Process Builder can call
    @InvocableMethod(label='Extracts Balance Information' description='Processes SMS record and extracts balance')
    public static List<SMS__c> extractBalanceInfo(List<SMS__c> smsList) {

        List<SMS__c> outputList = new List<SMS__c>();

        try {
            Map<String, Finance_Account__c> mapAccounts = getAccounts(smsList);

            // Ensure the list is not null or empty
            if (smsList == null || smsList.isEmpty()) {
                return null;
            }

            for (SMS__c sms1 : smsList) {
                String accountName = mapAccounts.get(sms1.Finance_Account__c).Name;
                SMS__c smsOutput = new SMS__c();

                if (accountName == 'HDFC SA') {
                    smsOutput = processForHDFCBankSA(sms1);
                } else if (accountName == 'ICICI SA') {
                    smsOutput = processForICICIBankSA(sms1);
                } else if (accountName == 'SBI SA') {
                    smsOutput = processForSBIBankSA(sms1);
                } else if (accountName == 'ICICI CC') {
                    smsOutput = processForICICIBankCC(sms1);
                } else if (accountName == 'ICICI AMAZON CC') {
                    smsOutput = processForICICIBankAmazonCC(sms1);
                }

                outputList.add(smsOutput);
            }

        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'extractBalanceInfo', e);
        }
        return outputList;
    }

    public static Map<String, Finance_Account__c> getAccounts(List<SMS__c> smsList) {
        Map<String, Finance_Account__c> allAccountsMap = new Map<String, Finance_Account__c>();
        List<String> allAccountIds = new List<String>();

        for (SMS__c sms1 : smsList) {
            if (sms1.Finance_Account__c != null) {
                allAccountIds.add(sms1.Finance_Account__c);
            }
        }

        List<Finance_Account__c> allAccounts = [SELECT Id, Name FROM Finance_Account__c WHERE Id IN :allAccountIds];

        for (Finance_Account__c fa : allAccounts) {
            allAccountsMap.put(fa.Id, fa);
        }
        return allAccountsMap;
    }

    // Processes SMS for ICICI Bank Amazon Credit Card
    public static SMS__c processForICICIBankAmazonCC(SMS__c sms1) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms1.Content__c.contains('spent using ICICI Bank Card XX7005')) {
                smsOutput.CC_Available_Balance__c = sms1.Content__c.split('Avl Limit: INR')[1].split('If not you')[0];
                smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.replace(' ', '').replace('INR', '').replace(',', '');
                if (smsOutput.CC_Available_Balance__c.endsWith('.')) {
                    smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.substring(0, smsOutput.CC_Available_Balance__c.length() - 1);
                }
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankAmazonCC', e);
        }

        return smsOutput;
    }

    // Processes SMS for HDFC Bank Savings Account
    public static SMS__c processForHDFCBankSA(SMS__c sms1) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms1.Content__c.contains('deposited')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
            } else if (sms1.Content__c.startsWith('Money Received')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl bal: INR')[1];
            } else if (sms1.Content__c.contains('debited from HDFC Bank XX9560')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl bal:INR ')[1].replace(',', '');
            } else if (sms1.Content__c.startsWith('Money Transferred - ')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
            } else if (sms1.Content__c.contains('spent Rs')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
            } else if (sms1.Content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 as on')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('INR ')[1].split(' on')[0];
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForHDFCBankSA', e);
        }

        return smsOutput;
    }

    // Processes SMS for SBI Bank Savings Account
    public static SMS__c processForSBIBankSA(SMS__c sms1) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms1.Content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            } else if (sms1.Content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForSBIBankSA', e);
        }

        return smsOutput;
    }

    // Processes SMS for ICICI Bank Credit Card
    public static SMS__c processForICICIBankCC(SMS__c sms1) {
        SMS__c smsOutput = new SMS__c();

        try {
            if (sms1.Content__c.contains('spent on ICICI Bank Card XX9006')) {
                smsOutput.CC_Available_Balance__c = sms1.Content__c.split('Avl Lmt: INR')[1].split('. To dispute')[0];
            }
            else if (sms1.Content__c.contains('spent using ICICI Bank Card XX9006')) {
                smsOutput.CC_Available_Balance__c = sms1.Content__c.split('Avl Limit')[1].split('If not you')[0].trim();
                if(smsOutput.CC_Available_Balance__c.endsWith('.')){
                    smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.substring(0, smsOutput.CC_Available_Balance__c.length() - 1);    
                }
                smsOutput.CC_Available_Balance__c = smsOutput.CC_Available_Balance__c.replace('INR', '').replace(':', '').trim().replace(',', '');
                
            }
        } catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'processForICICIBankCC', e);
        }

        return smsOutput;
    }

    // Processes SMS for ICICI Bank Savings Account
    public static SMS__c processForICICIBankSA(SMS__c sms1) {
        SMS__c smsOutput = new SMS__c();

        try { 
            if (sms1.Content__c.startsWith('ICICI Bank Account XX360 credited')){
                Pattern regex = Pattern.compile('Available Balance is Rs\\. ([\\d,]+\\.\\d{2})');
                Matcher matcher = regex.matcher(sms1.Content__c);
                if (matcher.find()) {
                    String availableBalance = matcher.group(1);
                    smsOutput.SA_Available_Balance__c = availableBalance;
                    System.debug('Extracted Available Balance: ' + availableBalance);
                }

                // Integer length = sms1.Content__c.split(' ').size();
                // smsOutput.SA_Available_Balance__c = sms1.Content__c.split(' ')[length-1];
            } 
            if (sms1.Content__c.startsWith('ICICI Bank Acct XX360 debited Rs.')) {
                smsOutput.SA_Available_Balance__c = sms1.Content__c.split('Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '');
            }
            // if(smsOutput.SA_Available_Balance__c.endsWith('.')){
            //     smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.substring(0, smsOutput.SA_Available_Balance__c.length() - 1);
            // }
            // smsOutput.SA_Available_Balance__c = smsOutput.SA_Available_Balance__c.replace(',', '');
        } 
        catch (Exception e) {
            FinPlanLogger.logError(CLASS_NAME, 'InvocableBalanceUpdateHandler.processForICICIBankSA', e);
        }

        return smsOutput;
    }
}