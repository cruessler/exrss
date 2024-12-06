import Feeds from '../elm/app/App/Feeds.elm';
import NewFeed from '../elm/app/App/NewFeed.elm';

import { Socket } from '../../deps/phoenix';
import { LiveSocket } from '../../deps/phoenix_live_view';

const hooks = {
  ElmModules: {
    mounted() {
      const elmModules = mountElmModules();

      const feedsModule = elmModules['App.Feeds'];

      if (feedsModule !== undefined) {
        joinChannels(feedsModule);
      }
    },
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  hooks,
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

const Elm = {
  App: { Feeds: Feeds.Elm.App.Feeds, NewFeed: NewFeed.Elm.App.NewFeed },
};

const mountElmModules = () => {
  const nodes = document.querySelectorAll('[data-elm-module]');

  return [...nodes].reduce((acc, node) => {
    // The module name may be `App` or `App.Feeds`. `modulePath` would be
    // ["App"] or ["App", "Feeds"], then.
    const moduleName = node.dataset.elmModule;
    const modulePath = moduleName.split('.');
    const elmModule = modulePath.reduce((acc, part) => acc[part], Elm);

    const params = JSON.parse(node.dataset.elmParams) || {};

    if (elmModule != undefined) {
      acc[moduleName] = elmModule.init({ node, flags: params });
    } else {
      console.error(`No module named ‘${moduleName}’ could be found`);
    }

    return acc;
  }, {});
};

const joinChannels = (feedsModule) => {
  const token = window.userToken;

  if (token === undefined || token.length === 0) {
    return;
  }

  const socket = new Socket('/socket', { params: { token } });

  socket.connect();

  const channel = socket.channel('user:self', {});
  channel.join();

  channel.on('unread_entries', (payload) => {
    const feed = payload.feed;

    if (feed !== undefined) {
      feedsModule.ports.unreadEntriesReceiver.send(feed);
    }
  });
};

window.addEventListener('phx:live_reload:attached', ({ detail: reloader }) => {
  reloader.enableServerLogs();
  window.liveReloader = reloader;
});
