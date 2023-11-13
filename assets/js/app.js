import Feeds from '../elm/app/App/Feeds.elm';
import NewFeed from '../elm/app/App/NewFeed.elm';

const Elm = {
  App: { Feeds: Feeds.Elm.App.Feeds, NewFeed: NewFeed.Elm.App.NewFeed },
};

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

const mountElmModules = () => {
  const nodes = document.querySelectorAll('[data-elm-module]');

  for (const node of nodes) {
    // The module name may be `App` or `App.Feeds`. `modulePath` would be
    // ["App"] or ["App", "Feeds"], then.
    const moduleName = node.dataset.elmModule;
    const modulePath = moduleName.split('.');
    const elmModule = modulePath.reduce((acc, part) => acc[part], Elm);

    const params = JSON.parse(node.dataset.elmParams) || {};

    if (elmModule != undefined) {
      elmModule.init({ node, flags: params });
    } else {
      console.error(`No module named ‘${moduleName}’ could be found`);
    }
  }
};

document.addEventListener('DOMContentLoaded', () => mountElmModules());
