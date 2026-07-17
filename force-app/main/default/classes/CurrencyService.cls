public with sharing class CurrencyService {

    public static Decimal getGbpToInrRate() {

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://api.frankfurter.app/latest?from=GBP&to=INR'
        );

        req.setMethod('GET');

        Http http = new Http();

        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){

            Map<String,Object> response =
                (Map<String,Object>)
                JSON.deserializeUntyped(
                    res.getBody()
                );

            Map<String,Object> rates =
                (Map<String,Object>)
                response.get('rates');

            return Decimal.valueOf(
                String.valueOf(
                    rates.get('INR')
                )
            );

        }

        return 1;

    }

}