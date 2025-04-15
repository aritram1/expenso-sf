
// delete script    

// List of object API names
List<String> objectApiNames = new List<String>{
    'SMS__c',
    'Transaction__c',
    'OTP__c',
    'Beneficiary__c',	
    'FlowInterview',
    'System_Log__c'
};

// Loop through the objects, query and delete records
for (String objectApiName : objectApiNames) {
    List<SObject> records = Database.query('SELECT Id FROM ' + objectApiName);
    if (!records.isEmpty()) {
        delete records;
        Database.emptyRecycleBin(records);
    }
}
