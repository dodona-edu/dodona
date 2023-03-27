import { events } from "state/PubSub";

export type Permission = "annotation.create"

let userId: number;
const permissions: Set<Permission> = new Set();

export function setUserId(id: number): void {
    userId = id;
    events.publish("getUserId");
}

export function getUserId(): number {
    return userId;
}

export function addPermission(permission: Permission): void {
    permissions.add(permission);
    events.publish("hasPermission");
}

export function hasPermission(permission: Permission): boolean {
    return permissions.has(permission);
}
