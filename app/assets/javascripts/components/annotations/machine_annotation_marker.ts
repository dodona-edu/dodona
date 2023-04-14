import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { VampireSlot } from "@boulevard/vampire";
import { createRef, ref, Ref } from "lit/directives/ref.js";

@customElement("d-machine-annotation-marker")
export class MachineAnnotationMarker extends ShadowlessLitElement {
    @property({ type: Object })
    data: MachineAnnotationData;

    render(): TemplateResult {
        return html`<span class="mark-${this.data.type}"><v-slot></v-slot></span><d-machine-annotation .data=${this.data}></d-machine-annotation>`;
    }
}
