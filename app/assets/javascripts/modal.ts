import { Modal } from "bootstrap";
import { render, TemplateResult } from "lit";


function showInfoModal(title: TemplateResult | string, content: TemplateResult | string, options?: {allowFullscreen: boolean}): void {
    const button = document.querySelector("#info-modal .modal-header #fullscreen-button") as HTMLElement;

    if (options?.allowFullscreen) {
        button.style.display = "inline";
    } else {
        button.style.display = "none";
    }

    render(title, document.querySelector("#info-modal .modal-title") as HTMLElement);
    render(content, document.querySelector("#info-modal .modal-body") as HTMLElement);

    const modal = new Modal(document.getElementById("info-modal"));
    modal.show();
}

export { showInfoModal };
