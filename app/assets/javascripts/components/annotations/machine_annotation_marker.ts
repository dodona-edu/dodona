import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { VampireSlot } from "@boulevard/vampire";
import { ref } from "lit/directives/ref.js";
import { createPopper, Instance as Popper } from "@popperjs/core";

/**
 * A marker that shows a tooltip with machine annotations.
 *
 * @prop {MachineAnnotationData[]} annotations The annotations to show in the tooltip.
 *
 * @element d-machine-annotation-marker
 */
@customElement("d-machine-annotation-marker")
export class MachineAnnotationMarker extends ShadowlessLitElement {
    @property({ type: Array })
    annotations: MachineAnnotationData[];

    // We need this to apply different styles to the marker when it is empty.
    // We can't use the :empty pseudo selector because the vampire slot is always present even if it is empty.
    @property({ state: true })
    empty: boolean;

    popper: Popper;

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

    initTooltip(tooltip: HTMLDivElement): void {
        if (!tooltip) {
            return;
        }

        if (this.popper) {
            this.popper.forceUpdate();
            return;
        }

        this.popper = createPopper(this, tooltip, {
            placement: "bottom-start",
            modifiers: [{ name: "flip" }],
        });
    }

    get firstAnnotation(): MachineAnnotationData {
        return this.annotations[0];
    }

    constructor() {
        super();
        // Popper fails to detect the marker appearing by a tab change.
        // We need to force an update when the marker becomes visible.
        const codeTab = document.querySelector("#link-to-code-tab");
        if (codeTab) {
            codeTab.addEventListener("click", () => {
                this.popper?.update();
            });
        }
    }

    render(): TemplateResult {
        return html`<span class="mark-${this.firstAnnotation.type} ${this.empty ? "mark-empty" : ""}"
        ><v-slot ${ref(s => this.initSlot(s as VampireSlot))}
        ></v-slot
        ></span
        ><div ${ref(t => this.initTooltip(t as HTMLDivElement))} class="marker-tooltip">${this.annotations.map(a => html`<d-machine-annotation .data=${a}></d-machine-annotation></div>`)}
        </div>`;
    }
}
