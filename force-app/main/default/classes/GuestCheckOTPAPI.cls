@RestResource(urlMapping='/api/login/otp/check')
global without sharing class GuestCheckOTPAPI {

    global final static String CLASS_NAME = 'GuestCheckOTPAPI';

    @HttpPost
    global static void checkOTP() {

        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            // Parse the incoming request body
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Validate the email and otp value in the request
            if (!requestData.containsKey('email') || String.isEmpty((String) requestData.get('email'))) {
                throw new FinPlanException('Email is required in the request body');
            }
            else if (!requestData.containsKey('otp') || String.isEmpty((String) requestData.get('otp'))) {
                throw new FinPlanException('OTP is required in the request body');
            }
            else{

                String providedEmail = (String) requestData.get('email');
                String providedOTP = (String) requestData.get('otp');
                
                // Check the OTP
                boolean matched = Util.checkOTP(providedEmail, providedOTP);
                
                if(matched){
                    // Set a successful response
                    RestContext.response.statusCode = 200; // Status : OK
                    Map<String, Object> responseBody = new Map<String, Object>();
                    responseBody.put('email', email);
                    responseBody.put('matched', 'OTP Matched successfully');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                }
                else {
                    RestContext.response.statusCode = 400; // Bad Request
                    Map<String, Object> responseBody = new Map<String, Object>();
                    responseBody.put('email', email);
                    responseBody.put('error', 'Invalid OTP');
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                }
            }
        } 
        catch (Exception e) {
            // Handle general exceptions
            FinPlanLogger.logError(CLASS_NAME, 'createOTP', e, null); // the last parameter is the entity Id, which is not available outside the loop
            RestContext.response.statusCode = 500; // Internal Server Error
            RestContext.response.responseBody = Blob.valueOf('Error processing otp check request: ' + e.getMessage() + '||' + e.getStackTraceString());
        }
    }

}