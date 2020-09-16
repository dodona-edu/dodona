interface CustomElement {
    element?: HTMLElement;
    outerHeight?: number;
    columnNumber?: number;
    cells?: CustomElement[];
}

export class Masonry {
    static readonly screenLgMin = 1200;
    static readonly bottomPadding = 24;

    roots: CustomElement[];

    constructor() {
        // subscribe to resize events
        window.addEventListener("resize", () => this.setCellLayout());
    }

    initMasonryRoots(): void {
        const rootElements = document.getElementsByClassName("masonry-root");
        this.roots = Array.from(rootElements).map((rootElement: HTMLElement) => {
            const cellElements: HTMLCollectionOf<Element> = rootElement.getElementsByClassName("masonry-cell");
            const cells: CustomElement[] = Array.from(cellElements).map((cellElement: HTMLElement) => {
                // Use child size because the cell size itself is changed a lot which causes gaps at the end of the columns
                const child: CSSStyleDeclaration = getComputedStyle(cellElement.children[0]);
                return {
                    outerHeight: parseInt(child.height) + parseInt(child.marginBottom) + parseInt(child.marginTop),
                    element: cellElement
                };
            });
            return { element: rootElement, columnNumber: 0, cells: cells };
        });
        // do the first layout
        this.setCellLayout();
    }

    setCellLayout(): void {
        for (const root of this.roots) {
            // only layout when the number of columns has changed
            const newColumnNumber = window.innerWidth >= Masonry.screenLgMin ? 2 : 1;
            if (newColumnNumber !== root.columnNumber) {
                // initialize
                root.columnNumber = newColumnNumber;

                // Construct array with empty CustomElements
                const columns: CustomElement[] = Array.from(new Array(root.columnNumber)).map(() => ({ outerHeight: 0, cells: [] }));

                // divide...
                for (const cell of root.cells) {
                    const minOuterHeight = Math.min(...columns.map(column => column.outerHeight));
                    const column = columns.find(column => column.outerHeight === minOuterHeight);
                    column.cells.push(cell);
                    column.outerHeight += cell.outerHeight + Masonry.bottomPadding;
                }

                // calculate masonry height
                const masonryHeight = Math.max(...columns.map(column => column.outerHeight));

                // ...and conquer
                let order = 0;
                for (const column of columns) {
                    for (const cell of column.cells) {
                        cell.element.style.order = `${order++}`;
                        // set the cell's flex-basis to 0
                        cell.element.style.flexBasis = "0";
                    }
                    // set flex-basis of the last cell to fill the
                    // leftover space at the bottom of the column
                    // to prevent the first cell of the next column
                    // to be rendered at the bottom of this column
                    if (column.cells.length !== 0) {
                        column.cells[column.cells.length - 1].element.style.flexBasis = `${column.cells[column.cells.length - 1].element.offsetHeight + masonryHeight - column.outerHeight - 1}px`;
                    }
                }

                // set the masonry height to trigger
                // re-rendering of all cells over columns
                // one pixel more than the tallest column
                root.element.style.maxHeight = `${masonryHeight}px`;
            }
        }
    }
}
