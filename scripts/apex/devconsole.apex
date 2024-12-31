String id = 'a00Qy00000XSepHIAT';

SMS__c sms = [SELECT id, Content__c, Transaction_Date__c, Beneficiary__c, amount__c, CC_Available_Balance__c, SA_Available_Balance__c, Finance_Account__c, create_Transaction__c, balance_update__c, beneficiary_name__c from SMS__c where id = :id];
sms.Amount__c = 10;
sms.beneficiary_name__c= 'Hello!';
sms.beneficiary_name__c= 'some id!';
List<SMS__c> smsList = new List<SMS__c>();
smsList.add(sms);

List<SMS__c> amountBeneficiary = InvocableBeneficiaryAmountUpdateHandler.extractBeneficiaryAndAmountFromSMS(smsList);
System.debug('Amount=>' + amountBeneficiary[0].amount__c);
System.debug('beneficiary_name__c=>' + amountBeneficiary[0].beneficiary_name__c);
System.debug('beneficiary=>' + amountBeneficiary[0].beneficiary__c);

List<SMS__c> balanceUpdate = InvocableBalanceUpdateHandler.extractBalanceInfo(smsList);
System.debug('SA Available Balance =>' + balanceUpdate[0].SA_Available_Balance__c);
System.debug('CC Available Balance =>' + balanceUpdate[0].CC_Available_Balance__c);
System.debug('Amount=>' + balanceUpdate[0].amount__c);

// SMS__c output = SMSProcessor.processForHDFCBankSA_BalanceUpdate(smsList[0]);
// System.debug('SA Available Balance =>' + output.SA_Available_Balance__c);
