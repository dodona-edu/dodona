import { events } from "state/PubSub";
import { AnnotationType } from "state/UserAnnotations";

export interface MachineAnnotationData {
    type: AnnotationType;
    text: string;
    row: number;
    externalUrl: string | null;
}

const machineAnnotationsByLine = new Map<number, MachineAnnotationData[]>();

export function setMachineAnnotations(annotations: MachineAnnotationData[]): void {
    machineAnnotationsByLine.clear();
    for (const annotation of annotations) {
        const line = annotation.row + 1 ?? 0;
        if (machineAnnotationsByLine.has(line)) {
            machineAnnotationsByLine.get(line)?.push(annotation);
        } else {
            machineAnnotationsByLine.set(line, [annotation]);
        }
    }
    events.publish("getMachineAnnotations");
}

export function getMachineAnnotationsByLine(line: number): MachineAnnotationData[] {
    return machineAnnotationsByLine.get(line) ?? [];
}
