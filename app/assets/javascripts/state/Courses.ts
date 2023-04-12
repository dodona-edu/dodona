import { stateProperty } from "state/state_system/StateProperty";
import { State } from "state/state_system/State";

class CourseState extends State {
    @stateProperty id: number;
}

export const courseState = new CourseState();
