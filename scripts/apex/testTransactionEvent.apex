// Create an instance of the platform event with the provided values
Transaction_Platform_Event__e txnPE = new Transaction_Platform_Event__e(
    Balance_Update__c = false,
    External_Id__c = '20241211003939000',
    Finance_Account__c = 'a03Qy00000CCLY2IAP',
    SMS_Content__c = 'Sent Rs.7.00 From HDFC Bank A/C x9560 To MONISEETA ROY GOSTHIPATY On 11/12/24 Ref 434626587819 Not You? Call 18002586161/SMS BLOCK UPI to 7308080808',
    SMS_Id__c = 'a00Qy00000VgamvIAB',
    Transaction_Date__c = DateTime.valueOf('2024-07-12 00:00:00').date(), // Use a comma instead of a semicolon
    Type__c = 'Debit'
);

// Call the SMSProcessor method
Transaction_Platform_Event__e updatedTxnPE = SMSProcessor.processForHDFCBankSA(txnPE);

// Debug the output
System.debug('Updated Transaction Platform Event: ' + updatedTxnPE);