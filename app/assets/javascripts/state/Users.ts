import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

export type Permission = "annotation.create"

class UserState extends State {
    @stateProperty id: number;
    @stateProperty private permissions: Set<Permission> = new Set<Permission>();

    addPermission(permission: Permission): void {
        // reassigning the set is necessary to trigger a state change
        this.permissions = new Set<Permission>([...this.permissions, permission]);
    }

    hasPermission(permission: Permission): boolean {
        return this.permissions.has(permission);
    }
}

export const userState = new UserState();
