public with sharing class Util {
    
    public static String clipTo255char(String str){
        return str.length() <= 255 ? str : str.substring(0, 255);
    }

    public static SMS__c populateTransactionDate(SMS__c sms){
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
        return sms;
    }

    public static String toCamelCase(String inputString) {
        if(inputString == null){
            return inputString;
        }
        else{
            List<String> modifiedWords = new List<String>();
            inputString = inputString.trim();

            // Split the string into words
            List<String> words = inputString.trim().split(' ');
            
            for (String word : words) {
                word = word.trim(); // trim the whitespaces
                if(word.length() == 1){
                    modifiedWords.add(word.toUpperCase());  // if there is only one character in the word
                }
                else if(word.length() > 1){ // if there are atleast 2 characters in a word
                    String firstAlphabet = word.substring(0, 1).toUpperCase();
                    String rest = word.substring(1, word.length()).toLowerCase();
                    modifiedWords.add(firstAlphabet + rest);
                }
            }

            // Join the words back together
            return String.join(modifiedWords, ' ');
            
        }
    }
     
}