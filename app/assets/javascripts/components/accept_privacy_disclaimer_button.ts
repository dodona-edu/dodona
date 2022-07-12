import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { fetch } from "util.js";

/**
 * This component represents the button to accept the privacy policy
 *
 * @element d-accept-privacy-disclaimer-button
 *
 * @prop {number} userId - The id of the user that accepts the privacy policy
 */
@customElement("d-accept-privacy-disclaimer-button")
export class AcceptPrivacyDisclaimerButton extends LitElement {
    @property({ type: Number, attribute: "user-id" })
    userId: number;

    async acceptPrivacyPolicy(): Promise<void> {
        const response = await fetch(`/${I18n.locale}/users/${this.userId}`, {
            method: "post",
            body: "_method=patch&user%5Baccepted_privacy_policy%5D=true",
            headers: {
                "Content-type": "application/x-www-form-urlencoded"
            },
        });
        if (response.status === 200) {
            Array.from(document.getElementsByClassName("privacy-disclaimer")).forEach( el => el.outerHTML = "" );
        }
    }

    constructor() {
        super();
        this.addEventListener("click", () => this.acceptPrivacyPolicy());
    }

    protected render(): TemplateResult {
        return html`<slot></slot>`;
    }
}
