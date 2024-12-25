// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import '../../deps/phoenix_html';

import { Socket } from '../../deps/phoenix';
import { LiveSocket } from '../../deps/phoenix_live_view';

import topbar from '../vendor/topbar';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
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
