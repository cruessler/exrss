// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import '../../deps/phoenix_html';

import { Socket } from '../../deps/phoenix';
import { LiveSocket } from '../../deps/phoenix_live_view';

import topbar from '../vendor/topbar';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

// See the following guide for how to configure colocated hooks. As of
// 2025-08-05 I did not make the required changes as there are no colocated
// hooks yet in this application.
// https://github.com/phoenixframework/phoenix_live_view/blob/v1.1.1/CHANGELOG.md
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 5000,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

window.addEventListener('phx:live_reload:attached', ({ detail: reloader }) => {
  reloader.enableServerLogs();
  window.liveReloader = reloader;
});
