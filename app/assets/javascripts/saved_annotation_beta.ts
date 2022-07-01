// REMOVE FILE AND USAGES AFTER CLOSED BETA

const BETA_COURSES = new Set([5]);

export function isBetaCourse(courseId: number): boolean {
    return BETA_COURSES.has(courseId);
}
