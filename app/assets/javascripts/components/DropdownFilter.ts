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
        selected: [string | number];
    @property()
        type: string;


    isAnySelected(): boolean {
        return this.selected.length > 0;
    }

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    selectLabel(name): void {
        if (dodona.addTokenToSearch) {
            dodona.addTokenToSearch(this.type, name);
        }
    }

    render(): TemplateResult {
        console.log(this);
        return html`
            <div class="dropdown dropdown-filter">
                <a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${I18n.t(`js.${this.type}`)}
                    ${this.isAnySelected() ? html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-${this.color}"></i>`: ""}
                    <i class="mdi mdi-chevron-down mdi-12"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.labels.map(s => html`
                        <li><a class="dropdown-item ${this.selected.includes(s.id) ? "active" : ""}" href="#" @click="${() => this.selectLabel(s.name)}">
                            ${this.multi ?
        html`
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" value="" id="flexCheckDefault">
                                        <label class="form-check-label" for="flexCheckDefault">
                                            ${ s.name } <span class="badge rounded-pill bg-info float-end">130</span>
                                        </label>
                                    </div>
                                ` :
        html`
                                    ${ s.name }  <span class="badge rounded-pill bg-info float-end">130</span>
                                `
}
                        </a></li>
                    `)}
                </ul>
            </div>
        `;
    }
}
