// Type definitions for https://www.npmjs.com/package/lit-element-state
// created by following this guide:
// https://medium.com/@ofir3322/add-your-own-type-definition-to-any-javascript-3rd-party-module-1fc6b11e6f10

import { LitElement } from "lit/development";


type Constructor = new (...args: any[]) => LitElement;
declare function observeState<T extends Constructor>(superClass: T): T;

declare class LitState {}

declare function stateVar(options?: any): any;

export { observeState, LitState, stateVar };
