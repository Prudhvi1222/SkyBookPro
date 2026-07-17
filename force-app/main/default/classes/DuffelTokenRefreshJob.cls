public class DuffelTokenRefreshJob implements Queueable {

    public void execute(QueueableContext context) {

        try {

            // Refresh token by calling Auth Service
            String token = DuffelAuthService.getAccessToken();

            System.debug('Duffel Token Refreshed Successfully');

            /*
             * If you have a Custom Setting to store tokens,
             * save the token here.
             *
             * Example:
             *
             * Duffel_Config__c cfg = Duffel_Config__c.getOrgDefaults();
             * cfg.Access_Token__c = token;
             * update cfg;
             */

            /*
             * BRD Requirement:
             * Chain itself if token expires within 10 minutes.
             *
             * Since DuffelAuthService currently reads from
             * Custom Metadata and does not expose expiry,
             * we simply demonstrate chaining.
             */

            // System.enqueueJob(new DuffelTokenRefreshJob());

        } catch (Exception e) {

            System.debug(
                'Token Refresh Failed: '
                + e.getMessage()
            );
        }
    }
}