@isTest
public class PassengerSearchServiceTest {

    @testSetup
    static void setupData() {
        Account a = TestDataFactory.createAccount('Search Test Corp');
        Contact c = TestDataFactory.createContact(a.Id, 'Usha', 'Pendyala');
        Flight__c f = TestDataFactory.createFlight('DEL', 'BOM', DateTime.now().addDays(5));
        TestDataFactory.createBookingWithStatus(c.Id, f.Id, 2, 'Confirmed');
    }

    @isTest
    static void testSearchPassengers_ByName() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        // SOSL requires fixed search results in test context
        Test.setFixedSearchResults(new List<Id>{ c.Id });

        Test.startTest();
        List<List<SObject>> results = PassengerSearchService.searchPassengers('Usha');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return at least one list');
    }

    @isTest
    static void testSearchPassengers_ByEmail() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.setFixedSearchResults(new List<Id>{ c.Id });

        Test.startTest();
        List<List<SObject>> results = PassengerSearchService.searchPassengers('usha@test.com');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @isTest
    static void testSearchPassengers_NoResults() {
        Test.startTest();
        List<List<SObject>> results = PassengerSearchService.searchPassengers('ZZZNOTFOUND999');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null even if empty');
    }
}