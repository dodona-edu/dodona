import { Notification } from "../../app/assets/javascripts/notification";

beforeEach(() => {
    jest.useFakeTimers();
    document.body.innerHTML = "<div class='notifications'></div>";
});

test("create notification with default settings", () => {
    new Notification("test notification");
    expect(document.body.innerHTML).toMatch("test notification");
    expect(document.body.innerHTML).not.toMatch("spinner");

    // hide
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Notification.hideDelay);
    jest.runAllTimers();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Notification.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test notification");
});

test("create notification with loading indicator", () => {
    new Notification("test notification", undefined, true);
    expect(document.body.innerHTML).toMatch("test notification");
    expect(document.body.innerHTML).toMatch("spinner");

    // hide
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Notification.hideDelay);
    jest.runAllTimers();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Notification.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test notification");
});

test("create persistent notification", () => {
    const n = new Notification("test notification", false);
    expect(document.body.innerHTML).toMatch("test notification");
    expect(document.body.innerHTML).not.toMatch("spinner");

    // hide
    expect(setTimeout).not.toHaveBeenLastCalledWith(expect.any(Function), Notification.hideDelay);

    n.hide();

    // remove after fade
    expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), Notification.removeDelay);
    jest.runAllTimers();

    expect(document.body.innerHTML).not.toMatch("test notification");
});
