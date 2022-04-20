async function fetchAnnouncements(): Promise<void> {
    const response = await fetch("/announcements.js?unread=true");
    eval(await response.text());
}

export { fetchAnnouncements };
