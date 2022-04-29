import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { queryParamSelectionMixin } from "mixins/query_param_selection_mixin";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

type Label = { id: string | number, name: string };

@customElement("dodona-dropdown-filter")
export class DropdownFilter extends queryParamSelectionMixin(ShadowlessLitElement) {
    @property({ type: Array })
    labels: Array<Label> = [];
    @property()
    color: (s: Label) => string;
    @property()
    type: string;

    @property()
    paramVal: (l: Label) => string;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    getSelectedLabels(): Array<Label> {
        return this.labels.filter(s => this.isSelected(this.paramVal(s)));
    }

    render(): TemplateResult {
        if (this.labels.length === 0) {
            return html``;
        }

        return html`
            <div class="dropdown dropdown-filter">
                <a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${this.getSelectedLabels().map( s => html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-${this.color(s)} left-icon"></i>`)}
                    ${I18n.t(`js.dropdown.${this.multi?"multi":"single"}.${this.type}`)}
                    <i class="mdi mdi-chevron-down mdi-18 right-icon"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.labels.map(s => html`
                            <li><span class="dropdown-item-text ">
                                <div class="form-check">
                                    <input class="form-check-input" type="${this.multi?"checkbox":"radio"}" .checked=${this.isSelected(this.paramVal(s))} @click="${() => this.toggle(this.paramVal(s))}" id="check-${this.param}-${s.id}">
                                    <label class="form-check-label" for="check-${this.param}-${s.id}">
                                        ${s.name}
                                    </label>
                                </div>
                            </span></li>
                    `)}
                </ul>
            </div>
        `;
    }
}
