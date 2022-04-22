import { Toast } from "../../app/assets/javascripts/toast";

beforeEach(() => {
    jest.useFakeTimers();
    document.body.innerHTML = "<section class='toasts'></section>";
});

test("create toast with default settings", () => {
    new Toast("test toast");
    expect(document.body.innerHTML).toMatch("test toast");
    expect(document.body.innerHTML).not.toMatch("spinner");

    // hide
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Toast.hideDelay);
    jest.runAllTimers();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Toast.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test toast");
});

test("create toast with loading indicator", () => {
    new Toast("test toast", undefined, true);
    expect(document.body.innerHTML).toMatch("test toast");
    expect(document.body.innerHTML).toMatch("spinner");

    // hide
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Toast.hideDelay);
    jest.runAllTimers();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Toast.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test toast");
});

test("create persistent toast", () => {
    const n = new Toast("test toast", false);
    expect(document.body.innerHTML).toMatch("test toast");
    expect(document.body.innerHTML).not.toMatch("spinner");

    // hide
    expect(setTimeout).not.toHaveBeenLastCalledWith(expect.any(Function), Toast.hideDelay);

    n.hide();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Toast.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test toast");
});
