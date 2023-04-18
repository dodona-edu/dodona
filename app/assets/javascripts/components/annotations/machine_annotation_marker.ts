import { customElement, property } from "lit/decorators.js";
import { css, html, LitElement, TemplateResult } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { VampireSlot } from "@boulevard/vampire";
import { createRef, ref, Ref } from "lit/directives/ref.js";

@customElement("d-machine-annotation-marker")
export class MachineAnnotationMarker extends ShadowlessLitElement {
    @property({ type: Array })
    annotations: MachineAnnotationData[];

    @property({ state: true })
    empty: boolean;

    setEmpty(slot: VampireSlot): void {
        this.empty = slot.assignedNodes().length === 0;
    }

    initSlot(slot: VampireSlot): void {
        if (!slot) {
            return;
        }

        slot.addEventListener("v::slotchange", () => this.setEmpty(slot));
        if (this.empty === undefined) {
            this.setEmpty(slot);
        }
    }

    get firstAnnotation(): MachineAnnotationData {
        return this.annotations[0];
    }

    render(): TemplateResult {
        return html`<span class="mark-${this.firstAnnotation.type} ${this.empty ? "mark-empty" : ""}"
        ><v-slot ${ref(s => this.initSlot(s as VampireSlot))}
        ></v-slot
        ></span
        ><div class="marker-tooltip">${this.annotations.map(a => html`<d-machine-annotation .data=${a}></d-machine-annotation></div>`)}
        </div>`;
    }
}
