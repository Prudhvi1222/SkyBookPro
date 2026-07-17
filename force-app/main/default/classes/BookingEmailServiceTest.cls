// BRD Section 10.1 & 11.1: Tests BookingEmailService @future method
@isTest
public class BookingEmailServiceTest {

    @testSetup
    static void setupData() {
        Account a = TestDataFactory.createAccount('Email Test Corp');
        Contact c = TestDataFactory.createContact(a.Id, 'Email', 'Tester');
        Flight__c f = TestDataFactory.createFlight('DEL', 'BOM', DateTime.now().addDays(5));
        TestDataFactory.createBookingWithStatus(c.Id, f.Id, 2, 'Confirmed');
    }

    // ── Test 1: Future email method executes without error ────────
    @isTest
    static void testSendConfirmationEmail() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        BookingEmailService.sendConfirmationEmail(new Set<Id>{ b.Id });
        Test.stopTest();

        System.assert(true, 'Email future method completed without exception');
    }

    // ── Test 2: Empty set doesn't throw error ─────────────────────
    @isTest
    static void testSendConfirmationEmail_EmptySet() {
        Test.startTest();
        BookingEmailService.sendConfirmationEmail(new Set<Id>());
        Test.stopTest();

        System.assert(true, 'Empty set should not throw error');
    }
}