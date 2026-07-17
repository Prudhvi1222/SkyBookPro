// BRD Section 8.3 & 14.1: Wrapper class to hold Duffel API flight offer data
// @AuraEnabled exposes all fields to LWC components
public class FlightOfferWrapper {

    @AuraEnabled public Id flightId;
    // BRD: Amadeus_Offer_ID__c — Duffel offer ID
    @AuraEnabled public String offerId;

    // BRD: Airline_Name__c
    @AuraEnabled public String airline;

    // Airline logo, taken directly from Duffel's carrier object
    // (logo_symbol_url). Left null when Duffel doesn't provide one for
    // that carrier — the LWC falls back to a generic icon in that case.
    @AuraEnabled public String airlineLogoUrl;

    // BRD: Name field on Flight__c
    @AuraEnabled public String flightNumber;

    // BRD: Origin_Airport__c
    @AuraEnabled public String origin;

    // BRD: Destination_Airport__c
    @AuraEnabled public String destination;

    // BRD: Departure_DateTime__c
    @AuraEnabled public String departureTime;

    // BRD: Arrival_DateTime__c
    @AuraEnabled public String arrivalTime;

    // BRD: Duration_Minutes__c
    @AuraEnabled public Integer durationMinutes;

    // BRD: Base_Fare__c — price per seat
    @AuraEnabled public Decimal price;

    // BRD: Currency from Duffel API response
    @AuraEnabled public String currency_x;

    // BRD: Seat_Class__c
    @AuraEnabled public String cabinClass;

    // BRD: Number of stops (Flight_Segment__c count)
    @AuraEnabled public Integer numberOfStops;

    // BRD: Available seats from Duffel offer
    @AuraEnabled public Integer seatsAvailable;

    // 'oneway' or 'roundtrip' — set by DuffelFlightSearchService based on the
    // search criteria, so the LWC can label/filter offers correctly.
    @AuraEnabled public String tripType;

    // Return leg (round-trip only) — parsed from slices[1] of the Duffel
    // offer. Left null for one-way offers.
    @AuraEnabled public String returnFlightNumber;
    @AuraEnabled public String returnAirline;
    @AuraEnabled public String returnAirlineLogoUrl;
    @AuraEnabled public String returnOrigin;
    @AuraEnabled public String returnDestination;
    @AuraEnabled public String returnDepartureTime;
    @AuraEnabled public String returnArrivalTime;
    @AuraEnabled public Integer returnDurationMinutes;
    @AuraEnabled public Integer returnNumberOfStops;

    // Id of the Flight__c record created for the return leg (round-trip
    // only). Passed back to BookingService.createBooking so the return
    // leg gets persisted as its own Flight_Segment__c alongside the
    // outbound leg, instead of being dropped at booking time.
    @AuraEnabled public Id returnFlightId;

    // Empty constructor — required for Apex instantiation
    public FlightOfferWrapper() {
    }

    // Parameterized constructor — used by DuffelFlightSearchService
    public FlightOfferWrapper(
    String offerId,
    String airline,
    String flightNumber,
    String origin,
    String destination,
    String departureTime,
    String arrivalTime,
    Integer durationMinutes,
    Decimal price,
    String currency_x,
    String cabinClass,
    Integer numberOfStops,
    Integer seatsAvailable
) {
    this.offerId = offerId;
    this.airline = airline;
    this.flightNumber = flightNumber;
    this.origin = origin;
    this.destination = destination;
    this.departureTime = departureTime;
    this.arrivalTime = arrivalTime;
    this.durationMinutes = durationMinutes;
    this.price = price;
    this.currency_x = currency_x;
    this.cabinClass = cabinClass;
    this.numberOfStops = numberOfStops;
    this.seatsAvailable = seatsAvailable;
}
}