@RestResource(urlMapping='/api/login/otp/create')
global without sharing class GuestCreateOTPAPI {

    global final static String CLASS_NAME = 'GuestOTPLoginAPI';

    /**
     * POST method to generate and send OTP
     * This method generates a 6-digit OTP, stores it in the OTP__c object, 
     * and sends it to the provided email.
     */
    @HttpPost
    global static void createOTP() {
        RestContext.response.addHeader('Content-Type', 'application/json');
        try {
            // Parse the incoming request body
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Validate the email field in the request
            if (!requestData.containsKey('email') || String.isEmpty((String) requestData.get('email'))) {
                throw new FinPlanException('Email is required in the request body');
            }
            else{
                String email = (String) requestData.get('email');
                // Generate the OTP
                String otp = Util.generateOTP(email);
                
                // Send the OTP to the provided email
                // NEW : 
                // The email is being sent from a RT Flow on OTP__c
                // So the following line is commented out
                // Util.sendEmail(email, otp);

                // Set a successful response
                RestContext.response.statusCode = 201; // Created
                Map<String, Object> responseBody = new Map<String, Object>();
                responseBody.put('otp', otp); // .substring(otp.length() - 3)); // Last three characters of the OTP
                responseBody.put('email', email);
                responseBody.put('expiry', Datetime.now().addMinutes(5).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
            }
        } 
        catch (Exception e) {
            // Handle general exceptions
            FinPlanLogger.logError(CLASS_NAME, 'createOTP', e, null); // the last parameter is the entity Id, which is not available outside the loop
            RestContext.response.statusCode = 500; // Internal Server Error
            Map<String, Object> responseBody = new Map<String, Object>();
            responseBody.put('error', 'Error processing request: ' + e.getMessage() + '||' + e.getStackTraceString());
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        }
    }

}