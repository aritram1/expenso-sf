String id = 'a00Qy00000WV2YmIAL';

SMS__c sms = [SELECT id, Content__c, Beneficiary__c, amount__c, CC_Available_Balance__c, SA_Available_Balance__c, Finance_Account__c, create_Transaction__c, balance_update__c, beneficiary_name__c from SMS__c where id = :id];
List<SMS__c> smsList = new List<SMS__c>();
smsList.add(sms);

// List<SMS__c> outputList1 = InvocableBeneficiaryAmountUpdateHandler.extractBeneficiaryAndAmountFromSMS(smsList);
SMS__c output = SMSProcessor.processForHDFCBankSA_BalanceUpdate(smsList[0]);
System.debug('SA Available Balance =>' + output.SA_Available_Balance__c);

// System.debug('Amount=>' + outputList1[0].Amount__c);
// System.debug('beneficiary_name__c=>' + outputList1[0].beneficiary_name__c);
// System.debug('beneficiary=>' + outputList1[0].beneficiary__c);

// List<SMS__c> outputList2 = InvocableBalanceUpdateHandler.extractBalanceInfo(smsList);
// System.debug('SA Available Balance =>' + outputList2[0].SA_Available_Balance__c);
// System.debug('CC Available Balance =>' + outputList2[0].CC_Available_Balance__c);