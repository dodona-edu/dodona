import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

type Label = { id: string | number, name: string };

@customElement("dodona-dropdown-filter")
export class DropdownFilter extends LitElement {
    @property({ type: Boolean })
    multi: boolean;
    @property({ type: Array })
    labels: Array<Label> = [];
    @property()
    color: (s: Label) => string;
    @property({ type: Array })
    selected: string[];
    @property()
    type: string;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    toggleLabel(s: Label): void {
        if (this.isSelected(s)) {
            if (dodona.deleteTokenFromSearch) {
                dodona.deleteTokenFromSearch(this.type, s.name);
            }
        } else {
            if (dodona.addTokenToSearch) {
                dodona.addTokenToSearch(this.type, s.name);
            }
        }
    }

    isSelected(s: Label): boolean {
        return this.selected.includes(s.name);
    }

    getSelectedLabels(): Array<Label> {
        return this.labels.filter(s => this.isSelected(s));
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
                                    <input class="form-check-input" type="${this.multi?"checkbox":"radio"}" .checked=${this.isSelected(s)} @click="${() => this.toggleLabel(s)}" id="check-${this.type}-${s.id}">
                                    <label class="form-check-label" for="check-${this.type}-${s.id}">
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
