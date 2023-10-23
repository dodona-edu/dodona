import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { ThemeOption } from "state/Theme";
import { fetch } from "utilities";

export type Permission = "annotation.create"

class UserState extends State {
    @stateProperty accessor id: number;
    @stateProperty private accessor permissions: Set<Permission> = new Set<Permission>();

    addPermission(permission: Permission): void {
        // reassigning the set is necessary to trigger a state change
        this.permissions = new Set<Permission>([...this.permissions, permission]);
    }

    hasPermission(permission: Permission): boolean {
        return this.permissions.has(permission);
    }

    update(user: { theme?: ThemeOption, id?: number }): void {
        // update the current user if no id is given
        const id = user.id ?? this.id;

        fetch(`/users/${id}`, {
            method: "PUT",
            body: JSON.stringify({ user }),
            headers: {
                "Content-type": "application/json",
                "Accept": "application/json"
            },
        });
    }
}

export const userState = new UserState();
