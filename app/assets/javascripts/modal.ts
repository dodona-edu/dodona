import { Modal } from "bootstrap";
import { render, TemplateResult } from "lit";


function showInfoModal(title: TemplateResult | string, content: TemplateResult | string): void {
    render(title, document.querySelector("#info-modal .modal-title") as HTMLElement);
    render(content, document.querySelector("#info-modal .modal-body") as HTMLElement);

    const modal = new Modal(document.getElementById("info-modal"));
    modal.show();
}

export { showInfoModal };
