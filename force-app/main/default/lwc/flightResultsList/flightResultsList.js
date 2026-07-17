import { LightningElement, api, track } from 'lwc';

export default class FlightResultsList extends LightningElement {
    @api flightOffers = [];

    @track sortBy = 'priceAsc';
    @track airlineFilter = '';
    @track maxPrice;

    get sortOptions() {
        return [
            { label: 'Price: Low to High', value: 'priceAsc' },
            { label: 'Price: High to Low', value: 'priceDesc' },
            { label: 'Duration', value: 'duration' },
            { label: 'Departure Time', value: 'departureTime' }
        ];
    }

    get filteredOffers() {
        let offers = [...(this.flightOffers || [])];

        if (this.airlineFilter) {
            const filterText = this.airlineFilter.toLowerCase();
            offers = offers.filter((offer) =>
                offer.airline &&
                offer.airline.toLowerCase().includes(filterText)
            );
        }

        if (this.maxPrice) {
            const max = Number(this.maxPrice);
            offers = offers.filter((offer) => Number(offer.price) <= max);
        }

        offers.sort((a, b) => {
            if (this.sortBy === 'priceAsc') {
                return Number(a.price || 0) - Number(b.price || 0);
            }

            if (this.sortBy === 'priceDesc') {
                return Number(b.price || 0) - Number(a.price || 0);
            }

            if (this.sortBy === 'duration') {
                return Number(a.durationMinutes || 0) - Number(b.durationMinutes || 0);
            }

            if (this.sortBy === 'departureTime') {
                return String(a.departureTime || '').localeCompare(
                    String(b.departureTime || '')
                );
            }

            return 0;
        });

        return offers;
    }

    get hasFilteredOffers() {
        return this.filteredOffers && this.filteredOffers.length > 0;
    }

    handleSortChange(event) {
        this.sortBy = event.detail.value;
    }

    handleAirlineFilterChange(event) {
        this.airlineFilter = event.target.value;
    }

    handleMaxPriceChange(event) {
        this.maxPrice = event.target.value;
    }

    handleSelectOffer(event) {
        this.dispatchEvent(
            new CustomEvent('offerselected', {
                detail: event.detail
            })
        );
    }
}