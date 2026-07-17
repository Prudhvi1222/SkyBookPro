import LightningDatatable from 'lightning/datatable';
import statusBadgeTemplate from './statusBadge.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        statusBadge: {
            template: statusBadgeTemplate,
            standardCellLayout: true,
            typeAttributes: ['status', 'badgeClass']
        }
    };
}