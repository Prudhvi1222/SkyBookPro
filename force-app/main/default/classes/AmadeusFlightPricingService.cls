public with sharing class AmadeusFlightPricingService {

    @AuraEnabled(cacheable=false)
    public static FlightOfferWrapper confirmPrice(
        String offerId,
        String offerJson
    ) {

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://api.duffel.com/air/offers/' +
            offerId
        );

        req.setMethod('GET');

        req.setHeader(
            'Authorization',
            DuffelAuthService.getAccessToken()
        );

        req.setHeader(
            'Duffel-Version',
            'v2'
        );

        req.setHeader(
            'Content-Type',
            'application/json'
        );

        Http http = new Http();

        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){

            throw new AuraHandledException(
                'Price confirmation failed.'
            );
        }

        Map<String,Object> parsed =
            (Map<String,Object>)
            JSON.deserializeUntyped(
                res.getBody()
            );

        Map<String,Object> data =
            (Map<String,Object>)
            parsed.get('data');

        FlightOfferWrapper wrapper =
            new FlightOfferWrapper();

        wrapper.offerId =
            (String)data.get('id');

        wrapper.price =
            Decimal.valueOf(
                String.valueOf(
                    data.get('total_amount')
                )
            );

        wrapper.currency_x =
            (String)data.get(
                'total_currency'
            );

        return wrapper;
    }
}