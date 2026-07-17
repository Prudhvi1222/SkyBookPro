public with sharing class PassengerSearchService {

    public static List<List<SObject>> searchPassengers(String searchTerm) {

        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Contact(Id, Name, Email),
                Booking__c(Name, Booking_Status__c)
        ];

        return searchResults;
    }
}