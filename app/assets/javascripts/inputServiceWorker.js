!function (e, t) {
    "object"==typeof exports&&"object"==typeof module?module.exports=t():"function"==typeof define&&define.amd?define([], t):"object"==typeof exports?exports.Papyros=t():e.Papyros=t();
}(self, (function () {
    return (()=>{
        const e={ 137: e=>{
            self, e.exports=(()=>{
                "use strict"; var e={ d: (t, r)=>{
                    for (const n in r)e.o(r, n)&&!e.o(t, n)&&Object.defineProperty(t, n, { enumerable: !0, get: r[n] });
                }, o: (e, t)=>Object.prototype.hasOwnProperty.call(e, t), r: e=>{
                    "undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e, Symbol.toStringTag, { value: "Module" }), Object.defineProperty(e, "__esModule", { value: !0 });
                } }; const t={}; e.r(t), e.d(t, { serviceWorkerFetchListener: ()=>u, asyncSleep: ()=>c, ServiceWorkerError: ()=>f, writeMessageAtomics: ()=>p, writeMessageServiceWorker: ()=>d, writeMessage: ()=>y, makeChannel: ()=>h, makeAtomicsChannel: ()=>v, makeServiceWorkerChannel: ()=>b, readMessage: ()=>w, syncSleep: ()=>g, uuidv4: ()=>l }); let r; const n=(r=function (e, t) {
                    return r=Object.setPrototypeOf||{ __proto__: [] }instanceof Array&&function (e, t) {
                        e.__proto__=t;
                    }||function (e, t) {
                        for (const r in t)Object.prototype.hasOwnProperty.call(t, r)&&(e[r]=t[r]);
                    }, r(e, t);
                }, function (e, t) {
                    if ("function"!=typeof t&&null!==t) throw new TypeError("Class extends value "+String(t)+" is not a constructor or null"); function n() {
                        this.constructor=e;
                    }r(e, t), e.prototype=null===t?Object.create(t):(n.prototype=t.prototype, new n);
                }); const o=function (e, t, r, n) {
                    return new(r||(r=Promise))((function (o, i) {
                        function a(e) {
                            try {
                                u(n.next(e));
                            } catch (e) {
                                i(e);
                            }
                        } function s(e) {
                            try {
                                u(n.throw(e));
                            } catch (e) {
                                i(e);
                            }
                        } function u(e) {
                            let t; e.done?o(e.value):(t=e.value, t instanceof r?t:new r((function (e) {
                                e(t);
                            }))).then(a, s);
                        }u((n=n.apply(e, t||[])).next());
                    }));
                }; const i=function (e, t) {
                    let r; let n; let o; let i; let a={ label: 0, sent: function () {
                        if (1&o[0]) throw o[1]; return o[1];
                    }, trys: [], ops: [] }; return i={ next: s(0), throw: s(1), return: s(2) }, "function"==typeof Symbol&&(i[Symbol.iterator]=function () {
                        return this;
                    }), i; function s(i) {
                        return function (s) {
                            return function (i) {
                                if (r) throw new TypeError("Generator is already executing."); for (;a;) {
                                    try {
                                        if (r=1, n&&(o=2&i[0]?n.return:i[0]?n.throw||((o=n.return)&&o.call(n), 0):n.next)&&!(o=o.call(n, i[1])).done) return o; switch (n=0, o&&(i=[2&i[0], o.value]), i[0]) {
                                        case 0: case 1: o=i; break; case 4: return a.label++, { value: i[1], done: !1 }; case 5: a.label++, n=i[1], i=[0]; continue; case 7: i=a.ops.pop(), a.trys.pop(); continue; default: if (!((o=(o=a.trys).length>0&&o[o.length-1])||6!==i[0]&&2!==i[0])) {
                                            a=0; continue;
                                        } if (3===i[0]&&(!o||i[1]>o[0]&&i[1]<o[3])) {
                                                a.label=i[1]; break;
                                            } if (6===i[0]&&a.label<o[1]) {
                                                a.label=o[1], o=i; break;
                                            } if (o&&a.label<o[2]) {
                                                a.label=o[2], a.ops.push(i); break;
                                            }o[2]&&a.ops.pop(), a.trys.pop(); continue;
                                        }i=t.call(e, a);
                                    } catch (e) {
                                        i=[6, e], n=0;
                                    } finally {
                                        r=o=0;
                                    }
                                } if (5&i[0]) throw i[1]; return { value: i[0]?i[1]:void 0, done: !0 };
                            }([i, s]);
                        };
                    }
                }; const a="__SyncMessageServiceWorkerInput__"; const s="__sync-message-v2__"; function u() {
                    const e={}; const t={}; return function (r) {
                        const n=r.request.url; return !!n.includes(a)&&(r.respondWith(function () {
                            return o(this, void 0, void 0, (function () {
                                function o(e) {
                                    const t={ message: e, version: s }; return new Response(JSON.stringify(t), { status: 200 });
                                } let a; let u; let c; let l; let f; let p; let d; let y; return i(this, (function (i) {
                                    switch (i.label) {
                                    case 0: return n.endsWith("/read")?[4, r.request.json()]:[3, 5]; case 1: return a=i.sent(), u=a.messageId, c=a.timeout, (l=e[u])?(delete e[u], [2, o(l)]):[3, 2]; case 2: return [4, new Promise((function (e) {
                                        t[u]=e, setTimeout((function () {
                                            delete t[u], e(new Response("", { status: 408 }));
                                        }), c);
                                    }))]; case 3: return [2, i.sent()]; case 4: return [3, 8]; case 5: return n.endsWith("/write")?[4, r.request.json()]:[3, 7]; case 6: return f=i.sent(), p=f.message, d=f.messageId, (y=t[d])?(y(o(p)), delete t[d]):e[d]=p, [2, o({ early: !y })]; case 7: if (n.endsWith("/version")) return [2, new Response(s, { status: 200 })]; i.label=8; case 8: return [2];
                                    }
                                }));
                            }));
                        }()), !0);
                    };
                } function c(e) {
                    return new Promise((function (t) {
                        return setTimeout(t, e);
                    }));
                } let l; var f=function (e) {
                    function t(r, n) {
                        const o=e.call(this, "Received status ".concat(n, " from ").concat(r, ". Ensure the service worker is registered and active."))||this; return o.url=r, o.status=n, Object.setPrototypeOf(o, t.prototype), o;
                    } return n(t, e), t;
                }(Error); function p(e, t) {
                    const r=(new TextEncoder).encode(JSON.stringify(t)); const n=e.data; const o=e.meta; if (r.length>n.length) throw "Input is too long"; n.set(r, 0), Atomics.store(o, 0, r.length), Atomics.store(o, 1, 1), Atomics.notify(o, 1);
                } function d(e, t, r) {
                    return o(this, void 0, void 0, (function () {
                        let n; let o; let a; let u; let l; return i(this, (function (i) {
                            switch (i.label) {
                            case 0: return [4, navigator.serviceWorker.ready]; case 1: i.sent(), n=e.baseUrl+"/write", o=Date.now(), i.label=2; case 2: return a={ message: t, messageId: r }, [4, fetch(n, { method: "POST", body: JSON.stringify(a) })]; case 3: return u=i.sent(), (l=200===u.status)?[4, u.json()]:[3, 5]; case 4: l=i.sent().version===s, i.label=5; case 5: return l?[2]:Date.now()-o<e.timeout?[4, c(100)]:[3, 7]; case 6: return i.sent(), [3, 2]; case 7: throw new f(n, u.status); case 8: return [2];
                            }
                        }));
                    }));
                } function y(e, t, r) {
                    return o(this, void 0, void 0, (function () {
                        return i(this, (function (n) {
                            switch (n.label) {
                            case 0: return "atomics"!==e.type?[3, 1]:(p(e, t), [3, 3]); case 1: return [4, d(e, t, r)]; case 2: n.sent(), n.label=3; case 3: return [2];
                            }
                        }));
                    }));
                } function h(e) {
                    return void 0===e&&(e={}), "undefined"!=typeof SharedArrayBuffer?v(e.atomics):"serviceWorker"in navigator?b(e.serviceWorker):null;
                } function v(e) {
                    const t=(void 0===e?{}:e).bufferSize; return { type: "atomics", data: new Uint8Array(new SharedArrayBuffer(t||131072)), meta: new Int32Array(new SharedArrayBuffer(2*Int32Array.BYTES_PER_ELEMENT)) };
                } function b(e) {
                    return void 0===e&&(e={}), { type: "serviceWorker", baseUrl: (e.scope||"/")+a, timeout: e.timeout||5e3 };
                } function m(e, t) {
                    return e>0?+e:t;
                } function w(e, t, r) {
                    const n=void 0===r?{}:r; const o=n.checkInterrupt; let i=n.checkTimeout; const a=n.timeout; const u=performance.now(); i=m(i, o?100:5e3); let c; const l=m(a, Number.POSITIVE_INFINITY); if ("atomics"===e.type) {
                        const p=e.data; const d=e.meta; c=function () {
                            if ("timed-out"===Atomics.wait(d, 1, 0, i)) return null; const e=Atomics.exchange(d, 0, 0); const t=p.slice(0, e); Atomics.store(d, 1, 0); const r=(new TextDecoder).decode(t); return JSON.parse(r);
                        };
                    } else {
                        c=function () {
                            const r=new XMLHttpRequest; const n=e.baseUrl+"/read"; r.open("POST", n, !1); const o={ messageId: t, timeout: i }; r.send(JSON.stringify(o)); const a=r.status; if (408===a) return null; if (200===a) {
                                const c=JSON.parse(r.responseText); return c.version!==s?null:c.message;
                            } if (performance.now()-u<e.timeout) return null; throw new f(n, a);
                        };
                    } for (;;) {
                        const y=l-(performance.now()-u); if (y<=0) return null; i=Math.min(i, y); const h=c(); if (null!==h) return h; if (null==o?void 0:o()) return null;
                    }
                } function g(e, t) {
                    if (e=m(e, 0)) {
                        if ("undefined"!=typeof SharedArrayBuffer) {
                            const r=new Int32Array(new SharedArrayBuffer(Int32Array.BYTES_PER_ELEMENT)); r[0]=0, Atomics.wait(r, 0, 0, e);
                        } else w(t, "sleep ".concat(e, " ").concat(l()), { timeout: e });
                    }
                } return l="randomUUID"in crypto?function () {
                    return crypto.randomUUID();
                }:function () {
                    return "10000000-1000-4000-8000-100000000000".replace(/[018]/g, (function (e) {
                        const t=Number(e); return (t^crypto.getRandomValues(new Uint8Array(1))[0]&15>>t/4).toString(16);
                    }));
                }, t;
            })();
        } }; const t={}; function r(n) {
            const o=t[n]; if (void 0!==o) return o.exports; const i=t[n]={ exports: {} }; return e[n](i, i.exports, r), i.exports;
        }r.r=e=>{
            "undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e, Symbol.toStringTag, { value: "Module" }), Object.defineProperty(e, "__esModule", { value: !0 });
        }; const n={}; return (()=>{
            "use strict"; r.r(n); const e=r(137); const t=function () {
                function t(t) {
                    this.syncMessageListener=(0, e.serviceWorkerFetchListener)(), this.hostName=t;
                } return t.prototype.handleInputRequest=function (e) {
                    return t=this, r=void 0, o=function () {
                        let t; return function (e, t) {
                            let r; let n; let o; let i; let a={ label: 0, sent: function () {
                                if (1&o[0]) throw o[1]; return o[1];
                            }, trys: [], ops: [] }; return i={ next: s(0), throw: s(1), return: s(2) }, "function"==typeof Symbol&&(i[Symbol.iterator]=function () {
                                return this;
                            }), i; function s(i) {
                                return function (s) {
                                    return function (i) {
                                        if (r) throw new TypeError("Generator is already executing."); for (;a;) {
                                            try {
                                                if (r=1, n&&(o=2&i[0]?n.return:i[0]?n.throw||((o=n.return)&&o.call(n), 0):n.next)&&!(o=o.call(n, i[1])).done) return o; switch (n=0, o&&(i=[2&i[0], o.value]), i[0]) {
                                                case 0: case 1: o=i; break; case 4: return a.label++, { value: i[1], done: !1 }; case 5: a.label++, n=i[1], i=[0]; continue; case 7: i=a.ops.pop(), a.trys.pop(); continue; default: if (!((o=(o=a.trys).length>0&&o[o.length-1])||6!==i[0]&&2!==i[0])) {
                                                    a=0; continue;
                                                } if (3===i[0]&&(!o||i[1]>o[0]&&i[1]<o[3])) {
                                                        a.label=i[1]; break;
                                                    } if (6===i[0]&&a.label<o[1]) {
                                                        a.label=o[1], o=i; break;
                                                    } if (o&&a.label<o[2]) {
                                                        a.label=o[2], a.ops.push(i); break;
                                                    }o[2]&&a.ops.pop(), a.trys.pop(); continue;
                                                }i=t.call(e, a);
                                            } catch (e) {
                                                i=[6, e], n=0;
                                            } finally {
                                                r=o=0;
                                            }
                                        } if (5&i[0]) throw i[1]; return { value: i[0]?i[1]:void 0, done: !0 };
                                    }([i, s]);
                                };
                            }
                        }(this, (function (r) {
                            return this.syncMessageListener(e)?[2, !0]:e.request.url.includes(this.hostName)?(t=fetch(e.request).then((function (e) {
                                const t=new Headers(e.headers); return t.set("Cross-Origin-Embedder-Policy", "require-corp"), t.set("Cross-Origin-Opener-Policy", "same-origin"), t.set("Cross-Origin-Resource-Policy", "cross-origin"), new Response(e.body, { status: e.status||200, statusText: e.statusText, headers: t });
                            })), e.respondWith(t), [2, !0]):[2, !1];
                        }));
                    }, new((n=void 0)||(n=Promise))((function (e, i) {
                        function a(e) {
                            try {
                                u(o.next(e));
                            } catch (e) {
                                i(e);
                            }
                        } function s(e) {
                            try {
                                u(o.throw(e));
                            } catch (e) {
                                i(e);
                            }
                        } function u(t) {
                            let r; t.done?e(t.value):(r=t.value, r instanceof n?r:new n((function (e) {
                                e(r);
                            }))).then(a, s);
                        }u((o=o.apply(t, r||[])).next());
                    })); let t; let r; let n; let o;
                }, t;
            }(); const o=new t(location.host); addEventListener("fetch", (function (e) {
                return t=this, r=void 0, i=function () {
                    return function (e, t) {
                        let r; let n; let o; let i; let a={ label: 0, sent: function () {
                            if (1&o[0]) throw o[1]; return o[1];
                        }, trys: [], ops: [] }; return i={ next: s(0), throw: s(1), return: s(2) }, "function"==typeof Symbol&&(i[Symbol.iterator]=function () {
                            return this;
                        }), i; function s(i) {
                            return function (s) {
                                return function (i) {
                                    if (r) throw new TypeError("Generator is already executing."); for (;a;) {
                                        try {
                                            if (r=1, n&&(o=2&i[0]?n.return:i[0]?n.throw||((o=n.return)&&o.call(n), 0):n.next)&&!(o=o.call(n, i[1])).done) return o; switch (n=0, o&&(i=[2&i[0], o.value]), i[0]) {
                                            case 0: case 1: o=i; break; case 4: return a.label++, { value: i[1], done: !1 }; case 5: a.label++, n=i[1], i=[0]; continue; case 7: i=a.ops.pop(), a.trys.pop(); continue; default: if (!((o=(o=a.trys).length>0&&o[o.length-1])||6!==i[0]&&2!==i[0])) {
                                                a=0; continue;
                                            } if (3===i[0]&&(!o||i[1]>o[0]&&i[1]<o[3])) {
                                                    a.label=i[1]; break;
                                                } if (6===i[0]&&a.label<o[1]) {
                                                    a.label=o[1], o=i; break;
                                                } if (o&&a.label<o[2]) {
                                                    a.label=o[2], a.ops.push(i); break;
                                                }o[2]&&a.ops.pop(), a.trys.pop(); continue;
                                            }i=t.call(e, a);
                                        } catch (e) {
                                            i=[6, e], n=0;
                                        } finally {
                                            r=o=0;
                                        }
                                    } if (5&i[0]) throw i[1]; return { value: i[0]?i[1]:void 0, done: !0 };
                                }([i, s]);
                            };
                        }
                    }(this, (function (t) {
                        switch (t.label) {
                        case 0: return [4, o.handleInputRequest(e)]; case 1: return t.sent()||e.respondWith(fetch(e.request)), [2];
                        }
                    }));
                }, new((n=void 0)||(n=Promise))((function (e, o) {
                    function a(e) {
                        try {
                            u(i.next(e));
                        } catch (e) {
                            o(e);
                        }
                    } function s(e) {
                        try {
                            u(i.throw(e));
                        } catch (e) {
                            o(e);
                        }
                    } function u(t) {
                        let r; t.done?e(t.value):(r=t.value, r instanceof n?r:new n((function (e) {
                            e(r);
                        }))).then(a, s);
                    }u((i=i.apply(t, r||[])).next());
                })); let t; let r; let n; let i;
            })), addEventListener("install", (function (e) {
                e.waitUntil(skipWaiting());
            })), addEventListener("activate", (function (e) {
                e.waitUntil(clients.claim());
            }));
        })(), n;
    })();
}));
