import { DodonaElement } from "components/meta/dodona_element";
import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import "components/search/loading_bar";
import { i18n } from "i18n/i18n";
import { exportLocation, prepareExport } from "export";

/**
 * This component represents a download button.
 * It should be used within a form.
 *
 * @element d-download-button
 */
@customElement("d-download-button")
export class DownloadButton extends DodonaElement {
    @property({ state: true })
    exportDataUrl: string | undefined = undefined;
    @property({ state: true })
    downloadUrl: string | undefined = undefined;

    private get form(): HTMLFormElement {
        return document.querySelector("#download_submissions") as HTMLFormElement;
    }

    private get started(): boolean {
        return this.exportDataUrl !== undefined;
    }

    private get ready(): boolean {
        return this.downloadUrl !== undefined;
    }

    private async download(): Promise<void> {
        const data = new FormData(this.form);
        // disable the form
        this.form.querySelectorAll("input, button")
            .forEach(e => e.setAttribute("disabled", "true"));
        this.exportDataUrl = await prepareExport(this.form.action, data);
        this.downloadUrl = await exportLocation(this.exportDataUrl);
        window.location.href = this.downloadUrl;
    }

    render(): TemplateResult {
        if (!this.started) {
            return html`
                <button @click=${() => this.download()} class="btn btn-filled">
                    ${i18n.t("js.download_button.download")}
                </button>
            `;
        } else if (this.ready) {
            return html`
                <p style="font-size: var(--d-font-size-base)">
                    ${i18n.t("js.download_button.ready")}
                </p>
                <a href=${this.downloadUrl} class="btn btn-outline">
                    ${i18n.t("js.download_button.retry")}
                </a>
                <button class="btn btn-filled" @click=${() => window.history.back()}>
                    ${i18n.t("js.download_button.go_back")}
                </button>
            `;
        } else {
            return html`
                <d-loading-bar loading="true"></d-loading-bar>
                <p class="help-block">${i18n.t("js.download_button.downloading")}</p>
            `;
        }
    }
}
