import { DodonaElement } from "components/meta/dodona_element";
import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";


export type DownloadResponse = {
    submissions: number;
    statusUrl: string;
    downloadUrl: string;
}

export type StatusResponse = {
    ready: boolean;
}

/**
 * This component represents a download button.
 * It should be used within a form.
 *
 * @element d-download-button
 */
@customElement("d-download-button")
export class DownloadButton extends DodonaElement {
    downloadResponse: DownloadResponse;
    @property({ state: true })
    ready = false;

    private get form(): HTMLFormElement {
        return this.closest("form") as HTMLFormElement;
    }

    private get started(): boolean {
        return this.downloadResponse !== undefined;
    }

    private get duration(): string {
        if (!this.started || this.ready) {
            return "";
        }

        if (this.downloadResponse.submissions < 1000) {
            return "This could take couple of seconds.";
        } else if (this.downloadResponse.submissions < 10000) {
            return "This could take a couple of minutes, you will receive a notification when the download is ready.";
        } else {
            return "This could take a while, you will receive a notification when the download is ready.";
        }
    }

    private async prepareDownload(): Promise<void> {
        const response = await fetch(this.form.action, {
            method: this.form.method,
            body: new FormData(this.form)
        });
        this.downloadResponse = await response.json();
        this.tryDownload();
    }

    private async tryDownload(): Promise<void> {
        if (!this.started || this.ready) {
            return;
        }

        const response = await fetch(this.downloadResponse.statusUrl);
        const data = await response.json();
        if (data.ready) {
            window.location.href = data.downloadResponse;
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
                <a href="${this.downloadResponse.downloadUrl}" class="btn btn-filled">Download again</a>
            `;
        } else {
            return html`
                <d-loading-bar loading="true"></d-loading-bar>
                <p>Preparing ${this.downloadResponse.submissions} submissions for download. ${this.duration}</p>
            `;
        }
    }
}
