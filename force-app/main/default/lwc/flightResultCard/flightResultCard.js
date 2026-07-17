import { LightningElement, api } from 'lwc';

export default class FlightResultCard extends LightningElement {
    @api offer;

    get displayAirline() {
        return this.offer?.airline || 'Airline';
    }

    get airlineLogoUrl() {
        return this.offer?.airlineLogoUrl || null;
    }

    get hasAirlineLogo() {
        return !!this.airlineLogoUrl;
    }

    get airlineInitial() {
        return this.displayAirline.charAt(0).toUpperCase();
    }

    get returnAirlineLogoUrl() {
        return this.offer?.returnAirlineLogoUrl || null;
    }

    get hasReturnAirlineLogo() {
        return !!this.returnAirlineLogoUrl;
    }

    get returnAirlineInitial() {
        return this.displayReturnAirline.charAt(0).toUpperCase();
    }

    get displayFlightNumber() {
        return this.offer?.flightNumber || 'N/A';
    }

    get displayCabinClass() {
        return this.offer?.cabinClass || 'Economy';
    }

    get isRoundTrip() {
        return this.offer?.tripType === 'roundtrip';
    }

    get tripTypeLabel() {
        return this.isRoundTrip ? 'Round Trip' : 'One Way';
    }

    get tripTypeBadgeClass() {
        return this.isRoundTrip
            ? 'frc-badge frc-badge-roundtrip'
            : 'frc-badge frc-badge-oneway';
    }

    get displayStops() {
        const stops = this.offer?.numberOfStops;

        if (stops === null || stops === undefined) {
            return 'N/A';
        }

        return stops === 0 ? 'Non-stop' : stops;
    }

    get displaySeats() {
        return this.offer?.seatsAvailable || 'N/A';
    }

    get displayDuration() {
        const minutes = Number(this.offer?.durationMinutes || 0);

        if (!minutes) {
            return 'N/A';
        }

        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;

        return `${hours}h ${remainingMinutes}m`;
    }

    get formattedDeparture() {
        return this.formatDateTime(this.offer?.departureTime);
    }

    get formattedArrival() {
        return this.formatDateTime(this.offer?.arrivalTime);
    }

    get displayReturnAirline() {
        return this.offer?.returnAirline || 'Airline';
    }

    get displayReturnFlightNumber() {
        return this.offer?.returnFlightNumber || 'N/A';
    }

    get displayReturnStops() {
        const stops = this.offer?.returnNumberOfStops;

        if (stops === null || stops === undefined) {
            return 'N/A';
        }

        return stops === 0 ? 'Non-stop' : stops;
    }

    get displayReturnDuration() {
        const minutes = Number(this.offer?.returnDurationMinutes || 0);

        if (!minutes) {
            return 'N/A';
        }

        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;

        return `${hours}h ${remainingMinutes}m`;
    }

    get formattedReturnDeparture() {
        return this.formatDateTime(this.offer?.returnDepartureTime);
    }

    get formattedReturnArrival() {
        return this.formatDateTime(this.offer?.returnArrivalTime);
    }

    handleSelect() {
        this.dispatchEvent(
            new CustomEvent('selectoffer', {
                detail: this.offer
            })
        );
    }

    formatDateTime(value) {
        if (!value) {
            return 'N/A';
        }

        try {
            return new Intl.DateTimeFormat('en-IN', {
                dateStyle: 'medium',
                timeStyle: 'short'
            }).format(new Date(value));
        } catch (e) {
            return value;
        }
    }
}