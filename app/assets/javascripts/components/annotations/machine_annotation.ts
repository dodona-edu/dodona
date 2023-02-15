import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { AnnotationType } from "code_listing/annotation";
import { Annotation } from "components/annotations/annotation";

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
export class MachineAnnotation extends Annotation {
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
    protected get meta(): TemplateResult {
        return html`
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
        `;
    }

    protected get class(): string {
        return "machine-annotation";
    }
}
