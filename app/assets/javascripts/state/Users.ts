import { events } from "state/PubSub";

let userId: number;

export function setUserId(id: number): void {
    userId = id;
    events.publish("getUserId");
}

export function getUserId(): number {
    return userId;
}
