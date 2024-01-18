import { i18nMixin } from "components/meta/i18n_mixin";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { StateController } from "state/state_system/StateController";

export class DodonaElement extends i18nMixin(ShadowlessLitElement) {
    constructor() {
        super();
        new StateController(this);
    }
}
