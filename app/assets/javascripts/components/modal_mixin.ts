import { html, TemplateResult, render } from "lit";
import { ref } from "lit/directives/ref.js";
import { Modal as Modal } from "bootstrap";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

export declare abstract class ModalMixinInterface {
    modalTemplate(title: TemplateResult, body: TemplateResult, footer: TemplateResult): TemplateResult;
    abstract get filledModalTemplate() :TemplateResult;
    showModal(): void;
    hideModal(): void;
}

type Constructor<T> = abstract new (...args: any[]) => T;

export function modalMixin<T extends Constructor<ShadowlessLitElement>>(superClass: T): Constructor<ModalMixinInterface> & T {
    abstract class ModalMixinClass extends superClass implements ModalMixinInterface {
        modal: Modal;

        private initModal(el: Element): void {
            if (!this.modal) {
                this.modal = new Modal(el);
            } else {
                this.modal.handleUpdate();
            }
        }

        modalTemplate(title: TemplateResult, body: TemplateResult, footer: TemplateResult): TemplateResult {
            return html`
                <div class="modal fade" ${ref(el => this.initModal(el))} tabindex="-1" role="dialog">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h4 class="modal-title">${title}</h4>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" @click=${() => this.hideModal()}></button>
                            </div>
                            <div class="modal-body">
                                ${body}
                            </div>
                            <div class="modal-footer">
                                ${footer}
                            </div>
                        </div>
                    </div>
                </div>`;
        }

        abstract get filledModalTemplate() :TemplateResult;

        update(changedProperties: Map<string, any>): void {
            super.update(changedProperties);
            this.renderModal();
        }

        private renderModal(): void {
            render(this.filledModalTemplate, document.getElementById("modal-container"), { host: this });
        }

        showModal(): void {
            this.renderModal();
            this.modal?.show();
        }

        hideModal(): void {
            this.modal?.hide();
        }
    }

    return ModalMixinClass as Constructor<ModalMixinInterface> & T;
}
