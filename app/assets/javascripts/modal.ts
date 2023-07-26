import { Modal } from "bootstrap";

function showInfoModal(title: string, content: string, options?: {allowFullscreen: boolean}): void {
    const button = document.querySelector("#info-modal .modal-header #fullscreen-button") as HTMLElement;

    if (options && options.allowFullscreen) {
        button.style.display = "inline";
    } else {
        button.style.display = "none";
    }

    document.querySelector("#info-modal .modal-title").innerHTML = title;
    document.querySelector("#info-modal .modal-body").innerHTML = `<p>${content}</p>`;

    const modal = new Modal(document.getElementById("info-modal"));
    modal.show();
}

export { showInfoModal };
