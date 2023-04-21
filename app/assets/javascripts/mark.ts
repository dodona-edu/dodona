export type range = { start: number, length: number, data?: unknown }; // data is optional
type callback = (node: Node, range: range) => void;

/**
 * Returns an array of text nodes or empty wrapper nodes and their start and end indices in the root node.
 * @param root The root node to search for text nodes.
 * @param wrapper The type of wrapper to search for.
 */
function getTextNodes(root: Node, wrapper: string): { start: number, end: number, node: Text; }[] {
    let val = "";
    const nodes = [];
    const iterator = document.createNodeIterator(root, NodeFilter.SHOW_ALL, node => {
        if (node.nodeType === Node.TEXT_NODE) {
            return NodeFilter.FILTER_ACCEPT;
        } else if (node.nodeName.toUpperCase() === wrapper.toUpperCase() && node.childNodes.length === 0) {
            // Accept empty wrapper nodes
            return NodeFilter.FILTER_ACCEPT;
        } else {
            return NodeFilter.FILTER_REJECT;
        }
    });

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

/**
 * Returns the closest wrapper node of the given type that is an ancestor of the given node.
 * @param node The node to search for a wrapper.
 * @param wrapper The type of wrapper to search for.
 */
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

/**
 * Wraps all elements in the given range of the root node in the given wrapper node.
 * For each part of the range that is already wrapped in the given wrapper node, the callback is called with the existing wrapper node.
 * For each part of the range that is not wrapped in the given wrapper node, the callback is called for the newly created wrapper node.
 *
 * If no text nodes are found in the root node, an empty wrapper node is created and the callback is called for it.
 *
 * @param root The root node to search for text nodes.
 * @param range The range to wrap.
 * @param wrapper The type of wrapper to create.
 * @param callback The callback to call for each wrapper node.
 */
function wrapRange(root: Node, range: range, wrapper: string, callback: callback): void {
    const start = range.start;
    const end = start + range.length;
    const nodes = getTextNodes(root, wrapper);

    let wrappedLength = 0;
    for (const node of nodes) {
        if (node.end > start && node.start <= end && node.node.textContent !== "\n" || (range.length === 0 && node.end === start)) {
            const closest = closestWrapper(node.node, wrapper);
            if (closest === null) {
                const splitStart = Math.max(0, start - node.start);
                let nodeToWrap = node.node;
                if (start > node.start) {
                    nodeToWrap = node.node.splitText(splitStart);
                }

                if (node.end > end) {
                    nodeToWrap.splitText(end - node.start - splitStart);
                }
                const wrapperNode = document.createElement(wrapper);
                wrapperNode.textContent = nodeToWrap.textContent;
                nodeToWrap.parentNode.replaceChild(wrapperNode, nodeToWrap);
                callback(wrapperNode, range);

                // Avoid needless wrapping of empty text nodes
                wrappedLength += wrapperNode.textContent.length;
                if (wrappedLength >= range.length) {
                    return;
                }
            } else {
                callback(closest, range);
                // Avoid needless wrapping of empty text nodes
                wrappedLength += closest.textContent.length;
                if (wrappedLength >= range.length) {
                    return;
                }
            }
        }
    }

    if (nodes.length === 0) {
        const wrapperNode = document.createElement(wrapper);
        wrapperNode.textContent = root.textContent;
        root.appendChild(wrapperNode);
        callback(wrapperNode, range);
    }
}

/**
 * Wraps all elements in the given ranges of the root node in the given wrapper node.
 * @param root The root node to search for text nodes.
 * @param ranges The ranges to wrap.
 * @param wrapper The type of wrapper to create.
 * @param callback The callback to call for each wrapper node.
 */
function wrapRanges(root: Node, ranges: range[], wrapper: string, callback: callback): void {
    ranges.forEach(range => wrapRange(root, range, wrapper, callback));
}

/**
 * Wraps all elements in the given ranges of the given target string in the given wrapper node.
 * @param target a html string whose text nodes should be wrapped
 * @param ranges the ranges of the textcontent to wrap
 * @param wrapper the type of wrapper to create
 * @param callback the callback to call for each wrapper node
 */
export function wrapRangesInHtml(target: string, ranges: range[], wrapper: string, callback: callback): string {
    const root = document.createElement("div");
    root.innerHTML = target;
    wrapRanges(root, ranges, wrapper, callback);
    return root.innerHTML;
}
