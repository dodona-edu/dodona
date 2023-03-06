// REMOVE FILE AND USAGES AFTER CLOSED BETA

const BETA_COURSES = new Set([10, 773, 1151, 1659, 2258]);

export function isBetaCourse(courseId: number): boolean {
    return BETA_COURSES.has(courseId);
}
