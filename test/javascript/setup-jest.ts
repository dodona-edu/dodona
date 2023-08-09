// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
declare let global: any;

// Mocking the I18N calls. The key itself will be returned as value.
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
global.I18n = {
    t: t => t,
    formatNumber: n => n.toString(),
    t_a: k => [],
};
