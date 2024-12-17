@isTest
private class InvocableSMSHandlerTest {

@isTest
    static void testProcessForICICIBankCC() {
        User usr = createTestUser();
        System.runAs(usr) {
            Test.startTest();
            Transaction_Platform_Event__c txn = new Transaction_Platform_Event__c();
            txn.Transaction_Amount__c = 100;
            txn.Transaction_Date__c = Date.today();
            txn.Finance_Account_Number__c = '1234';
            txn.Transaction_Status__c = 'Success';
            txn.Transaction_Type__c = 'Credit Card Charge';
            insert txn;
            Test.stopTest();
        }
        List<Transaction_Platform_Event__c> txnList = [SELECT Id, Name FROM Transaction_Platform_Event__c];
        System.assertEquals(1, txnList.size());
    }
@isTest
    static void testExtractBeneficiaryAndAccount() {
        User usr = createTestUser();
        System.runAs(usr) {
            // Create test data for Finance_Account__c records
            List<Finance_Account__c> financeAccounts = new List<Finance_Account__c>();
    
            // Add test records using the fields you need in Finance_Account__c
            Finance_Account__c financeAccount1 = new Finance_Account__c(
                Name = 'Test Finance Account',
                Account_Type__c = 'SAVING',
                Is_Active__c = true,
                Balance__c = 1000.00,
                Interest_Rate__c = 5.00,
                Minimum_Drawing_Amount__c = 100.00,
                Maximum_Drawing_Amount__c = 1000.00,
                Last_Transaction_Date__c = Date.today(),
                Last_Transaction_Time__c = DateTime.now(),
                Creation_Date_Time__c = DateTime.now(),
                Finance_Account_Number__c = '12345'
            );
            financeAccounts.add(financeAccount1);
    
            // ... add more test records for other account types and scenarios
            insert financeAccounts;
    
            // Create test data for Transaction_Platform_Event__c records
            List<Transaction_Platform_Event__c> transactions = new List<Transaction_Platform_Event__c>();
    
            // Add test records using the fields you need in Transaction_Platform_Event__c
            Transaction_Platform_Event__c transaction1 = new Transaction_Platform_Event__c(
                EventUuid = 'ABC123',
                Amount__c = 100.00,
                Transaction_Date__c = Date.today(),
                Type__c = 'Credit Card Charge',
                Related_Contact__c = [SELECT Id FROM Contact WHERE Name = 'John Doe'].Id,
                Finance_Account__c = financeAccounts[0].Id,
                Beneficiary__c = [SELECT Id FROM Beneficiary__c WHERE Name = 'HDFC Bank SA'].Id,
                Investment__c = [SELECT Id FROM Investment__c WHERE Name = 'SBI SA'].Id,
                External_Id__c = '12345',
                SMS_Content__c = 'Test message',
                SMS_Id__c = '67890',
                Balance_Update__c = false,
                Payment_Via__c = 'Credit Card',
                Payment_Reference__c = 'Ref123',
                SA_Available_Balance__c = 1000.00,
                CC_Available_Balance__c = 2000.00,
                Beneficiary_Name__c = 'John Doe',
                Payment_Via__c = 'Credit Card',
                Payment_Reference__c = 'Ref123'
            );
            transactions.add(transaction1);
    
            // ... add more test records for other scenarios
            insert transactions;
    
            // Call the method you want to test
            List<Transaction_Platform_Event__c> outputList = InvocableSMSHandler.extractBeneficiaryAndAccount(transactions);
    
            // Perform assertions to validate the results
            System.assertEquals(1, outputList.size());
            // Add more assertions for other scenarios
        }
    }
}