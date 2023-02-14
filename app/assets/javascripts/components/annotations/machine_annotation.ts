import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { AnnotationType } from "code_listing/annotation";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl: string | null;
}

/**
 *
 */
@customElement("d-machine-annotation")
export class MachineAnnotation extends ShadowlessLitElement {
    @property({ type: Object })
    data: MachineAnnotationData;

    protected get hasNotice(): boolean {
        return this.data.externalUrl !== null && this.data.externalUrl !== undefined;
    }

    protected get text(): string {
        return this.data.text.split("\n")
            .filter(s => !s.match("^--*$"))
            .join("\n");
    }

    render(): TemplateResult {
        return html`
            <d-annotation-template class="machine-annotation" text="${this.text}">
                <span v-slot="meta">
                    ${I18n.t(`js.annotation.type.${this.data.type}`)}
                    ${this.hasNotice ? html`
                        <span>
                            ·
                            <a href="${this.data.externalUrl}" target="_blank">
                                <i class="mdi mdi-information mdi-18 colored-info"
                                   title="${I18n.t("js.machine_annotation.external_url")}"
                                   data-bs-toggle="tooltip"
                                   data-bs-placement="top"
                                ></i>
                            </a>
                        </span>
                    ` : ""}
                </span>
                <v-slot name="buttons" v-slot="buttons"></v-slot>
                <v-slot name="footer" v-slot="footer"></v-slot>
            </d-annotation-template>
        `;
    }
}
