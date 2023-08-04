import { State } from "state/state_system/State";

/**
 * Factory function to create a class that inherits from `State`
 * And implements an interface T.
 *
 * It has a default constructor that receives an object of type T
 * and assigns all its properties to the new instance.
 *
 * Should be used for json objects that are received from the server.
 */
export const createStateFromInterface = <T>(): new (data: T) => (T & State) => {
    class MyClass extends State {
        constructor(data: T) {
            super();
            Object.keys(data).forEach(key => {
                (this as any)[key] = data[key];
            });
        }
    }

    return MyClass as new (data: T) => (T & State);
};
