import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { Toast } from "toast";
import { fetch } from "utilities";
import { searchQueryState } from "state/SearchQuery";
import { DodonaElement } from "components/meta/dodona_element";
export type SearchAction = {
    url?: string,
    type?: string,
    text: string,
    action?: string,
    js?: string,
    confirm?: string,
    icon: string
};

/**
 * This component represents a dropdown containing a combination of SearchOptions and SearchActions
 *
 * @element d-search-actions
 *
 * @prop {(SearchOption|SearchAction)[]} actions - the array of SearchOptions/Actions to be displayed in the dropdown
 */
@customElement("d-search-actions")
export class SearchActions extends DodonaElement {
    @property({ type: Array })
    actions: SearchAction[] = [];

    async performAction(action: SearchAction): Promise<boolean> {
        if (!action.action && !action.js) {
            return true;
        }

        if (!action.action) {
            eval(action.js);
            return false;
        }

        if (action.confirm === undefined || window.confirm(action.confirm)) {
            const url: string = searchQueryState.addParametersToUrl(action.action);

            const response = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" }
            });
            const data = await response.json();
            new Toast(data.message);
            if (data.js) {
                eval(data.js);
            } else {
                searchQueryState.arrayQueryParams.clear();
                searchQueryState.queryParams.clear();
            }
        }

        return false;
    }


    render(): TemplateResult | TemplateResult[] {
        if (this.actions.length === 0) {
            return html``;
        }

        return this.actions.map(action => html`
            <a class="btn btn-outline with-icon m-2 me-0"
               href='${action.url ? action.url : "#"}'
               data-type="${action.type}"
               @click=${() => this.performAction(action)}
            >
                <i class='mdi mdi-${action.icon} mdi-18'></i>
                ${action.text}
            </a>
        `);
    }
}
