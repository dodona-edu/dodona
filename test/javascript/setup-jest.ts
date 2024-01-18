// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
declare let global: any;

import { i18n } from "i18n/i18n";
jest.spyOn(i18n, "t").mockImplementation((key: string) => key);
