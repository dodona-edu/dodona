import { html, css, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

@customElement("dodona-dropdown-filter")
export class DropdownFilter extends LitElement {
    // @property()
    // paramVal: (s: {id: number, name: string}) => unknown;
    @property({ type: Boolean })
        multi: boolean;
    @property( { type: Array } )
        labels: Array<{id: string | number, name: string}>=[];
    @property()
        color: string;
    @property( { type: Array } )
        selected: [string];
    @property()
        type: string;


    isAnySelected(): boolean {
        return this.selected.length > 0;
    }

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    toggleLabel(s: {id: string | number, name: string}): void {
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

    isSelected(s: {id: string | number, name: string}): boolean{
        return this.selected.includes(s.name);
    }

    render(): TemplateResult {
        return html`
            <div class="dropdown dropdown-filter">
                <a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${I18n.t(`js.${this.type}`)}
                    ${this.isAnySelected() ? html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-${this.color}"></i>`: ""}
                    <i class="mdi mdi-chevron-down mdi-12"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.labels.map(s => html`
                        ${this.multi ?
                            html`
                                <li><a class="dropdown-item " href="#">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" .value=${this.isSelected(s)}
                                               @click="${() => this.toggleLabel(s)}" id="check-${this.type}-${s.id}">
                                        <label class="form-check-label" for="check-${this.type}-${s.id}">
                                            ${s.name} <span class="badge rounded-pill bg-info float-end">130</span>
                                        </label>
                                    </div>
                                </a></li>
                            ` :
                            html`
                                <li><a class="dropdown-item ${this.isSelected(s) ? "active" : ""}" href="#"
                                       @click="${() => this.toggleLabel(s)}">
                                    ${s.name} <span class="badge rounded-pill bg-info float-end">130</span>
                                </a></li>
                            `
                        }
                    `)}
                </ul>
            </div>
        `;
    }
}
