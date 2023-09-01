// REMOVE FILE AND USAGES AFTER CLOSED BETA

import { courseState } from "state/Courses";

const BETA_COURSES = new Set([10, 773, 1151, 1659, 1662, 2258, 2263]);

export function isBetaCourse(courseId?: number): boolean {
    return BETA_COURSES.has(courseId || courseState.id );
}
