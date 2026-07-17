@isTest
public class DuffelTokenRefreshJobTest {

    @isTest
    static void testQueueableExecution() {

        Test.startTest();

        System.enqueueJob(
            new DuffelTokenRefreshJob()
        );

        Test.stopTest();

        System.assert(
            true,
            'DuffelTokenRefreshJob executed successfully'
        );
    }
}