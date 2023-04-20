import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { VampireSlot } from "@boulevard/vampire";
import { ref } from "lit/directives/ref.js";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";

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

    static tippyInstances: Tippy[] = [];
    static tippySingleton = createSingleton([], {
        placement: "bottom-start",
        interactive: true,
        interactiveDebounce: 25,
        delay: [500, 25],
        offset: [-10, 2],
        moveTransition: "transform 0.001s ease-out",
        appendTo: () => document.querySelector(".code-table"),
    });
    static registerTippyInstance(instance: Tippy): void {
        this.tippyInstances.push(instance);
        this.tippySingleton.setInstances(this.tippyInstances);
    }

    tippy: Tippy;

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
        if (!tooltip || this.tippy) {
            return;
        }

        this.tippy = tippy(this, {
            content: tooltip,
        });
        MachineAnnotationMarker.registerTippyInstance(this.tippy);
    }

    get markClasses(): string {
        const hiddenTypes = this.annotations.map(a => a.type);
        return [...new Set(hiddenTypes)].map(t => `mark-${t}`).join(" ");
    }

    render(): TemplateResult {
        return html`<span class="${this.markClasses} ${this.empty ? "mark-empty" : ""}"
        ><v-slot ${ref(s => this.initSlot(s as VampireSlot))}
        ></v-slot
        ></span
        ><div ${ref(t => this.initTooltip(t as HTMLDivElement))} class="marker-tooltip">${this.annotations.map(a => html`<d-machine-annotation .data=${a}></d-machine-annotation>`)}
        </div>`;
    }
}
