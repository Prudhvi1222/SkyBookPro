@isTest
public class TestDataFactory {

    // BRD 11.2: Creates an Account (Corporate travel account)
    public static Account createAccount(String name) {
        Account a = new Account(
            Name = name
        );
        insert a;
        return a;
    }

    // BRD 11.2: Creates a Contact linked to Account
    public static Contact createContact(Id accountId, String firstName, String lastName) {
        Contact c = new Contact(
            AccountId = accountId,
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '@test.com'
        );
        insert c;
        return c;
    }

    // BRD 11.2: Creates a Flight with specific departure time
    public static Flight__c createFlight(String origin, String destination, DateTime departure) {
        Flight__c f = new Flight__c(
            Origin_Airport__c = origin,
            Destination_Airport__c = destination,
            Departure_DateTime__c = departure,
            Arrival_DateTime__c = departure.addHours(2),
            Airline_Name__c = 'TA123',
            Duration_Minutes__c = 120,
            Status__c = 'Active'
        );
        insert f;
        return f;
    }

    // BRD 11.2: Creates a Booking with seat count
    public static Booking__c createBooking(Id contactId, Id flightId, Integer seats) {
        Booking__c b = new Booking__c(
            Passenger__c = contactId,
            Flight__c = flightId,
            Seat_Class__c = 'Economy',
            Number_Of_Seats__c = seats,
            Base_Fare__c = 5000,
            Taxes_Fees__c = 500,
            Booking_Status__c = 'Draft',
            Booking_Date__c = Date.today()
        );
        insert b;
        return b;
    }

    // Helper: Creates a Booking with specific status (used by CancellationServiceTest)
    public static Booking__c createBookingWithStatus(Id contactId, Id flightId, Integer seats, String status) {
        Booking__c b = new Booking__c(
            Passenger__c = contactId,
            Flight__c = flightId,
            Seat_Class__c = 'Economy',
            Number_Of_Seats__c = seats,
            Base_Fare__c = 5000,
            Taxes_Fees__c = 500,
            Booking_Status__c = status,
            Booking_Date__c = Date.today()
        );
        insert b;
        return b;
    }

    // BRD 11.2: Creates a Refund record
    public static Refund__c createRefund(Id bookingId, Decimal amount) {
        Refund__c r = new Refund__c(
            Booking__c = bookingId,
            Refund_Amount__c = amount,
            Refund_Status__c = 'Initiated',
            Requested_Date__c = Date.today()
        );
        insert r;
        return r;
    }
}