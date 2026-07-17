public class DuffelAuthService {

    // BRD Section: Retrieves Duffel API Bearer token from Custom Metadata
    public static String getAccessToken() {

        // Query API key from Custom Metadata
        List<Duffel_Config__mdt> configs = [
        SELECT API_Key__c
        FROM Duffel_Config__mdt
        LIMIT 1
        ];

        // Error handling: no config record found
        if (configs.isEmpty()) {
            throw new AuraHandledException('Duffel API configuration not found. Please check Custom Metadata.');
        }

        // Error handling: token is blank
        if (String.isBlank(configs[0].API_Key__c)) {
            throw new AuraHandledException('Duffel API token is empty. Please update Custom Metadata record.');
        }

        return 'Bearer ' + configs[0].API_Key__c;
    }
}