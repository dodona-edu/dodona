import { AnnotationType } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { StateMap } from "state/state_system/StateMap";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl?: string | null;
}

class MachineAnnotationState extends State {
    @stateProperty public byLine = new StateMap<number, MachineAnnotationData[]>();
    @stateProperty public count = 0;

    public setMachineAnnotations(annotations: MachineAnnotationData[]): void {
        this.count = annotations.length;
        this.byLine.clear();
        for (const annotation of annotations) {
            const line = annotation.row + 1 ?? 0;
            if (this.byLine.has(line)) {
                this.byLine.get(line)?.push(annotation);
            } else {
                this.byLine.set(line, [annotation]);
            }
        }
    }
}

export const machineAnnotationState = new MachineAnnotationState();
