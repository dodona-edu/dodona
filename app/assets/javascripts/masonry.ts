interface CustomElement {
  element?: HTMLElement;
  outerHeight?: number;
  columnNumber?: number;
  cells?: Array<CustomElement>;
}

export class Masonry {
  static readonly minColWidth = 1;
  roots: Array<CustomElement>;

  constructor() {
    // subscribe to load and resize events
    window.addEventListener('load', () => this.onLoad());
    window.addEventListener('resize', () => this.onResize());
  }
  
  onLoad() :void {
    let rootElements = document.getElementsByClassName('masonry-root');
    this.roots = Array.prototype.map.call(rootElements, (rootElement: HTMLElement) => {
      let cellElements: HTMLCollectionOf<Element> = rootElement.getElementsByClassName('masonry-cell');
      let cells: Array<CustomElement> = Array.prototype.map.call(cellElements, function(cellElement: HTMLElement) {
        let style = getComputedStyle(cellElement);
        return { 
          outerHeight: parseInt(style.marginTop) + cellElement.offsetHeight + parseInt(style.marginBottom),
          element: cellElement
        }
      });
      return { element: rootElement, columnNumber: 0, cells: cells };
    });
  
    // do the first layout
    this.onResize();
  }

  onResize() :void {
    for (let root of this.roots) {
    
      // only layout when the number of columns has changed
      let newColumnNumber = 2;
      if (newColumnNumber != root.columnNumber) {
  
        // initialize
        root.columnNumber = newColumnNumber;
        let columns = Array.from(new Array(root.columnNumber)).map( () => {
          let rootElement: CustomElement = { outerHeight: 0 };
          rootElement.cells = new Array();
          return rootElement;
        });
        
        // divide...
        for (let cell of root.cells) {
          let minOuterHeight = Math.min(...columns.map( function(column) {
            return column.outerHeight;
          }));
          let column = columns.find((column) => column.outerHeight == minOuterHeight);
          column.cells.push(cell);
          column.outerHeight += cell.outerHeight;
        }
        
        // calculate masonry height
        let masonryHeight = Math.max(...columns.map((column) => column.outerHeight));
        
        // ...and conquer
        let order = 0;
        for (let column of columns) {
          for (let cell of column.cells) {
            cell.element.style.order = String(order++);
            // set the cell's flex-basis to 0
            cell.element.style.flexBasis = '0';
          }
          // set flex-basis of the last cell to fill the
          // leftover space at the bottom of the column
          // to prevent the first cell of the next column
          // to be rendered at the bottom of this column
          if (column.cells.length !== 0) {
            column.cells[column.cells.length - 1].element.style.flexBasis = String(column.cells[column.cells.length - 1].element.offsetHeight + masonryHeight - column.outerHeight - 1) + 'px';
          }
        }
  
        // set the masonry height to trigger
        // re-rendering of all cells over columns
        // one pixel more than the tallest column
        root.element.style.maxHeight = String(masonryHeight + 1) + 'px';
  
        console.log(columns.map( (column) => column.outerHeight));
        console.log(root.element.style.maxHeight);
      }
    }
  }
}
