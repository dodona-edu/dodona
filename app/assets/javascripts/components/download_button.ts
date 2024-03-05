import { DodonaElement } from "components/meta/dodona_element";
import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import "components/search/loading_bar";

/**
 * This component represents a download button.
 * It should be used within a form.
 *
 * @element d-download-button
 */
@customElement("d-download-button")
export class DownloadButton extends DodonaElement {
    @property({ state: true })
    ready = false;
    @property({ state: true })
    exportUrl: string | undefined = undefined;

    private get form(): HTMLFormElement {
        return document.querySelector("#download_submissions") as HTMLFormElement;
    }

    private get started(): boolean {
        return this.exportUrl !== undefined;
    }

    private async prepareDownload(): Promise<void> {
        const data = new FormData(this.form);
        // disable the form
        this.form.querySelectorAll("input, button")
            .forEach(e => e.setAttribute("disabled", "true"));
        const response = await fetch(this.form.action, {
            method: this.form.method,
            body: data,
            headers: {
                "Accept": "application/json"
            }
        });
        const json = await response.json();
        this.exportUrl = json.url;
        this.tryDownload();
    }

    private async tryDownload(): Promise<void> {
        if (!this.started || this.ready) {
            return;
        }

        const response = await fetch(this.exportUrl);
        const data = await response.json();
        if (data.ready) {
            window.location.href = data.url;
            this.ready = true;
        } else {
            setTimeout(() => this.tryDownload(), 1000);
        }
    }

    render(): TemplateResult {
        if (!this.started) {
            return html`
                <button @click=${() => this.prepareDownload()} class="btn btn-filled">Download</button>
            `;
        } else if (this.ready) {
            return html`
                <button class="btn btn-filled" @click=${() => window.history.back()}>Done, go back</button>
            `;
        } else {
            return html`
                <d-loading-bar loading="true"></d-loading-bar>
                <p class="help-block">
                    Preparing submissions for download, this might take a couple of minutes.
                    Do not close this page.
                </p>
            `;
        }
    }
}
