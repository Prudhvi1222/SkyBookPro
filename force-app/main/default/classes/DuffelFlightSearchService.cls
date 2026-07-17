public with sharing class DuffelFlightSearchService {

    @AuraEnabled(cacheable=false)
    public static List<FlightOfferWrapper> searchFlights(
        String origin,
        String destination,
        String departureDate,
        String returnDate,
        String tripType,
        String cabinClass,
        Integer adults
    ) {
        if (String.isBlank(origin)) {
            throw new AuraHandledException('Origin airport is required.');
        }

        if (String.isBlank(destination)) {
            throw new AuraHandledException('Destination airport is required.');
        }

        if (String.isBlank(departureDate)) {
            throw new AuraHandledException('Departure date is required.');
        }

        Boolean isRoundTrip = tripType == 'roundtrip';

        if (isRoundTrip && String.isBlank(returnDate)) {
            throw new AuraHandledException('Return date is required for round-trip search.');
        }

        if (adults == null || adults < 1) {
            adults = 1;
        }

        if (String.isBlank(cabinClass)) {
            cabinClass = 'economy';
        }

        String passengersJson = buildPassengersJson(adults);
        String slicesJson = buildSlicesJson(
            origin,
            destination,
            departureDate,
            returnDate,
            isRoundTrip
        );

        String body =
            '{"data":{' +
                '"slices":' + slicesJson + ',' +
                '"passengers":' + passengersJson + ',' +
                '"cabin_class":"' + String.escapeSingleQuotes(cabinClass.toLowerCase()) + '"' +
            '}}';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.duffel.com/air/offer_requests?return_offers=true');
        req.setMethod('POST');
        req.setHeader('Authorization', DuffelAuthService.getAccessToken());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Duffel-Version', 'v2');
        req.setBody(body);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException(
                'Flight search failed. Status: ' +
                res.getStatusCode() +
                ', Response: ' +
                res.getBody()
            );
        }

        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        Map<String, Object> data =
            (Map<String, Object>) parsed.get('data');

        List<Object> offers =
            (List<Object>) data.get('offers');

        List<FlightOfferWrapper> results = new List<FlightOfferWrapper>();

        if (offers == null || offers.isEmpty()) {
            return results;
        }

        List<Flight__c> flightsToInsert = new List<Flight__c>();
        List<FlightOfferWrapper> wrappersToPopulate = new List<FlightOfferWrapper>();
        // Parallel lists tracking where each wrapper's outbound/return
        // Flight__c records land in flightsToInsert once inserted, since a
        // round-trip offer contributes two Flight__c rows (outbound +
        // return) instead of one.
        List<Integer> outboundIndexByWrapper = new List<Integer>();
        List<Integer> returnIndexByWrapper = new List<Integer>();

        for (Object o : offers) {
            Map<String, Object> offer = (Map<String, Object>) o;

            FlightOfferWrapper wrapper = parseOfferToWrapper(
                offer,
                origin,
                destination,
                cabinClass
            );

            wrapper.tripType = isRoundTrip ? 'roundtrip' : 'oneway';

            if (isRoundTrip) {
                populateReturnLeg(wrapper, offer, destination, origin);
            }

            Flight__c flight = new Flight__c(
                Flight_Number__c = wrapper.flightNumber,
                Origin_Airport__c = wrapper.origin,
                Destination_Airport__c = wrapper.destination,
                Departure_DateTime__c = parseDateTime(wrapper.departureTime),
                Arrival_DateTime__c = parseDateTime(wrapper.arrivalTime),
                Airline_Name__c = wrapper.airline,
                Duration_Minutes__c = wrapper.durationMinutes,
                Status__c = 'Active',
                Amadeus_Offer_ID__c = wrapper.offerId
            );

            flightsToInsert.add(flight);
            Integer outboundIdx = flightsToInsert.size() - 1;

            Integer returnIdx = -1;

            if (isRoundTrip) {
                Flight__c returnFlight = new Flight__c(
                    Flight_Number__c = wrapper.returnFlightNumber,
                    Origin_Airport__c = wrapper.returnOrigin,
                    Destination_Airport__c = wrapper.returnDestination,
                    Departure_DateTime__c = parseDateTime(wrapper.returnDepartureTime),
                    Arrival_DateTime__c = parseDateTime(wrapper.returnArrivalTime),
                    Airline_Name__c = wrapper.returnAirline,
                    Duration_Minutes__c = wrapper.returnDurationMinutes,
                    Status__c = 'Active',
                    // Amadeus_Offer_ID__c is unique on Flight__c. The
                    // outbound leg above already uses the raw wrapper.offerId,
                    // so the return leg needs a distinct-but-traceable value
                    // (same offer id + a "-RET" suffix) instead of reusing
                    // the same value, which would violate the unique index
                    // and fail the whole search with a DUPLICATE_VALUE error.
                    Amadeus_Offer_ID__c = wrapper.offerId + '-RET'
                );

                flightsToInsert.add(returnFlight);
                returnIdx = flightsToInsert.size() - 1;
            }

            wrappersToPopulate.add(wrapper);
            outboundIndexByWrapper.add(outboundIdx);
            returnIndexByWrapper.add(returnIdx);
        }

        if (!flightsToInsert.isEmpty()) {
            insert flightsToInsert;
        }

        for (Integer i = 0; i < wrappersToPopulate.size(); i++) {
            wrappersToPopulate[i].flightId =
                flightsToInsert[outboundIndexByWrapper[i]].Id;

            Integer returnIdx = returnIndexByWrapper[i];

            if (returnIdx != -1) {
                wrappersToPopulate[i].returnFlightId =
                    flightsToInsert[returnIdx].Id;
            }

            results.add(wrappersToPopulate[i]);
        }

        return results;
    }

    /**
     * Builds the "slices" array for the Duffel offer request.
     * One-way -> single slice (origin -> destination on departureDate).
     * Round-trip -> two slices: outbound + the return leg
     * (destination -> origin on returnDate).
     */
    private static String buildSlicesJson(
        String origin,
        String destination,
        String departureDate,
        String returnDate,
        Boolean isRoundTrip
    ) {
        String outboundSlice =
            '{' +
                '"origin":"' + String.escapeSingleQuotes(origin) + '",' +
                '"destination":"' + String.escapeSingleQuotes(destination) + '",' +
                '"departure_date":"' + String.escapeSingleQuotes(departureDate) + '"' +
            '}';

        if (!isRoundTrip) {
            return '[' + outboundSlice + ']';
        }

        String returnSlice =
            '{' +
                '"origin":"' + String.escapeSingleQuotes(destination) + '",' +
                '"destination":"' + String.escapeSingleQuotes(origin) + '",' +
                '"departure_date":"' + String.escapeSingleQuotes(returnDate) + '"' +
            '}';

        return '[' + outboundSlice + ',' + returnSlice + ']';
    }

    private static FlightOfferWrapper parseOfferToWrapper(
        Map<String, Object> offer,
        String fallbackOrigin,
        String fallbackDestination,
        String requestedCabinClass
    ) {
        FlightOfferWrapper w = new FlightOfferWrapper();

        w.offerId = (String) offer.get('id');

        if (offer.containsKey('total_amount') && offer.get('total_amount') != null) {
            w.price = Decimal.valueOf(String.valueOf(offer.get('total_amount')));
        } else {
            w.price = 0;
        }

        w.currency_x = (String) offer.get('total_currency');
        // Default to whatever cabin the person actually searched for -
        // this used to be hardcoded to 'Economy' regardless of the search,
        // which is why Business/First searches still showed Economy on the
        // card. Overridden below with the real per-segment value when
        // Duffel returns one.
        w.cabinClass = formatCabinClass(requestedCabinClass);
        w.seatsAvailable = 9;

        List<Object> slices = (List<Object>) offer.get('slices');

        if (slices != null && !slices.isEmpty()) {
            Map<String, Object> firstSlice =
                (Map<String, Object>) slices[0];

            List<Object> segments =
                (List<Object>) firstSlice.get('segments');

            w.numberOfStops =
                segments == null || segments.isEmpty()
                ? 0
                : segments.size() - 1;

            if (segments != null && !segments.isEmpty()) {
                Map<String, Object> firstSegment =
                    (Map<String, Object>) segments[0];

                Map<String, Object> lastSegment =
                    (Map<String, Object>) segments[segments.size() - 1];

                Map<String, Object> originObj =
                    (Map<String, Object>) firstSegment.get('origin');

                Map<String, Object> destinationObj =
                    (Map<String, Object>) lastSegment.get('destination');

                Map<String, Object> operatingCarrier =
                    (Map<String, Object>) firstSegment.get('operating_carrier');

                Map<String, Object> marketingCarrier =
                    (Map<String, Object>) firstSegment.get('marketing_carrier');

                w.origin =
                    originObj != null && originObj.containsKey('iata_code')
                    ? (String) originObj.get('iata_code')
                    : fallbackOrigin;

                w.destination =
                    destinationObj != null && destinationObj.containsKey('iata_code')
                    ? (String) destinationObj.get('iata_code')
                    : fallbackDestination;

                w.departureTime =
                    (String) firstSegment.get('departing_at');

                w.arrivalTime =
                    (String) lastSegment.get('arriving_at');

                w.flightNumber =
                    String.valueOf(firstSegment.get('flight_number'));

                if (String.isBlank(w.flightNumber)) {
                    w.flightNumber = 'DF-' + String.valueOf(DateTime.now().getTime());
                }

                if (operatingCarrier != null && operatingCarrier.containsKey('name')) {
                    w.airline = (String) operatingCarrier.get('name');
                } else if (marketingCarrier != null && marketingCarrier.containsKey('name')) {
                    w.airline = (String) marketingCarrier.get('name');
                } else {
                    w.airline = 'Duffel Airline';
                }

                if (operatingCarrier != null && operatingCarrier.get('logo_symbol_url') != null) {
                    w.airlineLogoUrl = (String) operatingCarrier.get('logo_symbol_url');
                } else if (marketingCarrier != null && marketingCarrier.get('logo_symbol_url') != null) {
                    w.airlineLogoUrl = (String) marketingCarrier.get('logo_symbol_url');
                }

                String segmentCabinClass = extractSegmentCabinClass(firstSegment);

                if (String.isNotBlank(segmentCabinClass)) {
                    w.cabinClass = formatCabinClass(segmentCabinClass);
                }

                w.durationMinutes = calculateDurationMinutes(
                    w.departureTime,
                    w.arrivalTime
                );
            }
        }

        if (String.isBlank(w.origin)) {
            w.origin = fallbackOrigin;
        }

        if (String.isBlank(w.destination)) {
            w.destination = fallbackDestination;
        }

        if (String.isBlank(w.airline)) {
            w.airline = 'Duffel Airline';
        }

        if (String.isBlank(w.flightNumber)) {
            w.flightNumber = 'DF-' + String.valueOf(DateTime.now().getTime());
        }

        if (w.durationMinutes == null) {
            w.durationMinutes = 0;
        }

        return w;
    }

    /**
     * Round-trip Duffel offers come back with two slices: slices[0] is the
     * outbound leg (already handled by parseOfferToWrapper) and slices[1] is
     * the return leg. This was previously never read, so return-trip
     * searches only ever showed the outbound flight to the user.
     */
    private static void populateReturnLeg(
        FlightOfferWrapper wrapper,
        Map<String, Object> offer,
        String fallbackOrigin,
        String fallbackDestination
    ) {
        List<Object> slices = (List<Object>) offer.get('slices');

        if (slices == null || slices.size() < 2) {
            return;
        }

        Map<String, Object> returnSlice = (Map<String, Object>) slices[1];
        List<Object> segments = (List<Object>) returnSlice.get('segments');

        wrapper.returnNumberOfStops =
            segments == null || segments.isEmpty()
            ? 0
            : segments.size() - 1;

        if (segments == null || segments.isEmpty()) {
            return;
        }

        Map<String, Object> firstSegment = (Map<String, Object>) segments[0];
        Map<String, Object> lastSegment =
            (Map<String, Object>) segments[segments.size() - 1];

        Map<String, Object> originObj =
            (Map<String, Object>) firstSegment.get('origin');

        Map<String, Object> destinationObj =
            (Map<String, Object>) lastSegment.get('destination');

        Map<String, Object> operatingCarrier =
            (Map<String, Object>) firstSegment.get('operating_carrier');

        Map<String, Object> marketingCarrier =
            (Map<String, Object>) firstSegment.get('marketing_carrier');

        wrapper.returnOrigin =
            originObj != null && originObj.containsKey('iata_code')
            ? (String) originObj.get('iata_code')
            : fallbackOrigin;

        wrapper.returnDestination =
            destinationObj != null && destinationObj.containsKey('iata_code')
            ? (String) destinationObj.get('iata_code')
            : fallbackDestination;

        wrapper.returnDepartureTime = (String) firstSegment.get('departing_at');
        wrapper.returnArrivalTime = (String) lastSegment.get('arriving_at');

        wrapper.returnFlightNumber =
            String.valueOf(firstSegment.get('flight_number'));

        if (String.isBlank(wrapper.returnFlightNumber)) {
            wrapper.returnFlightNumber = 'DF-R-' + String.valueOf(DateTime.now().getTime());
        }

        if (operatingCarrier != null && operatingCarrier.containsKey('name')) {
            wrapper.returnAirline = (String) operatingCarrier.get('name');
        } else if (marketingCarrier != null && marketingCarrier.containsKey('name')) {
            wrapper.returnAirline = (String) marketingCarrier.get('name');
        } else {
            wrapper.returnAirline = 'Duffel Airline';
        }

        if (operatingCarrier != null && operatingCarrier.get('logo_symbol_url') != null) {
            wrapper.returnAirlineLogoUrl = (String) operatingCarrier.get('logo_symbol_url');
        } else if (marketingCarrier != null && marketingCarrier.get('logo_symbol_url') != null) {
            wrapper.returnAirlineLogoUrl = (String) marketingCarrier.get('logo_symbol_url');
        }

        wrapper.returnDurationMinutes = calculateDurationMinutes(
            wrapper.returnDepartureTime,
            wrapper.returnArrivalTime
        );
    }

    /**
     * Duffel returns the actual booked cabin per segment under
     * segments[].passengers[].cabin_class (e.g. "economy", "business").
     * This is the ground truth for what the offer was actually priced in,
     * which can occasionally differ from the class searched for.
     */
    private static String extractSegmentCabinClass(Map<String, Object> segment) {
        if (segment == null) {
            return null;
        }

        List<Object> segmentPassengers = (List<Object>) segment.get('passengers');

        if (segmentPassengers == null || segmentPassengers.isEmpty()) {
            return null;
        }

        Map<String, Object> firstPassenger = (Map<String, Object>) segmentPassengers[0];

        if (firstPassenger == null) {
            return null;
        }

        return (String) firstPassenger.get('cabin_class');
    }

    private static String formatCabinClass(String rawCabinClass) {
        if (String.isBlank(rawCabinClass)) {
            return 'Economy';
        }

        String normalized = rawCabinClass.toLowerCase().trim();

        if (normalized == 'premium_economy') {
            return 'Premium Economy';
        }

        if (normalized == 'business') {
            return 'Business';
        }

        if (normalized == 'first') {
            return 'First';
        }

        return 'Economy';
    }

    private static String buildPassengersJson(Integer adults) {
        List<String> passengerItems = new List<String>();

        for (Integer i = 0; i < adults; i++) {
            passengerItems.add('{"type":"adult"}');
        }

        return '[' + String.join(passengerItems, ',') + ']';
    }

    private static DateTime parseDateTime(String value) {
        if (String.isBlank(value)) {
            return DateTime.now().addDays(1);
        }

        try {
            String normalized = value.replace('T', ' ');

            if (normalized.contains('+')) {
                normalized = normalized.substringBefore('+');
            }

            if (normalized.endsWith('Z')) {
                normalized = normalized.replace('Z', '');
            }

            return DateTime.valueOf(normalized);
        } catch (Exception e) {
            return DateTime.now().addDays(1);
        }
    }

    private static Integer calculateDurationMinutes(
        String departureValue,
        String arrivalValue
    ) {
        try {
            DateTime departureDateTime = parseDateTime(departureValue);
            DateTime arrivalDateTime = parseDateTime(arrivalValue);

            Long diffMillis =
                arrivalDateTime.getTime() - departureDateTime.getTime();

            return Integer.valueOf(diffMillis / (1000 * 60));
        } catch (Exception e) {
            return 0;
        }
    }
}