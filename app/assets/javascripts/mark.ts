import { html, render } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";

type range = { start: number, length: number, data?: unknown }; // data is optional
type callback = (node: Node, range: range) => void;

function getTextNodes(root: Node): { start: number, end: number, node: Text; }[] {
    let val = "";
    const nodes = [];
    const iterator = document.createNodeIterator(root, NodeFilter.SHOW_TEXT);

    let node;
    while (node = iterator.nextNode()) {
        nodes.push({
            start: val.length,
            end: (val += node.textContent).length,
            node
        });
    }
    return nodes;
}

function closestWrapper(node: Node, wrapper: string): Node | null {
    let parent = node;
    while (parent !== null) {
        if (parent.nodeName.toUpperCase() === wrapper.toUpperCase()) {
            return parent;
        }
        parent = parent.parentNode;
    }
    return null;
}


function wrapRange(root: Node, range: range, wrapper: string, callback: callback): void {
    const start = range.start;
    const end = start + range.length;
    const nodes = getTextNodes(root);
    nodes.forEach(node => {
        if (node.end >= start && node.start < end && node.node.textContent !== "") {
            const closest = closestWrapper(node.node, wrapper);
            if ( closest === null ) {
                const splitStart = Math.max(0, start - node.start);
                const splitEnd = Math.min(node.end, end) - node.start - splitStart;
                const startNode = node.node.splitText(splitStart);
                startNode.splitText(splitEnd);
                const wrapperNode = document.createElement(wrapper);
                wrapperNode.textContent = startNode.textContent;
                startNode.parentNode.replaceChild(wrapperNode, startNode);
                callback(wrapperNode, range);
            } else {
                callback(closest, range);
            }
        }
    });

    if (nodes.length === 0) {
        const wrapperNode = document.createElement(wrapper);
        wrapperNode.textContent = root.textContent;
        root.appendChild(wrapperNode);
        callback(wrapperNode, range);
    }
}

function wrapRanges(root: Node, ranges: range[], wrapper: string, callback: callback): void {
    ranges.forEach(range => wrapRange(root, range, wrapper, callback));
}

export function wrapRangesInHtml(target: string, ranges: range[], wrapper: string, callback: callback): string {
    const root = document.createElement("div");
    render(html`${unsafeHTML(target)}`, root);
    wrapRanges(root, ranges, wrapper, callback);
    return root.innerHTML;
}
