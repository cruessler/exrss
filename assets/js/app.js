// We need to import the CSS so that webpack will load it.
// The ExtractTextPlugin is used to separate it out into
// its own CSS file.
import css from '../css/app.scss';

// webpack automatically concatenates all files in your
// watched paths. Those paths can be configured as
// endpoints in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import Feeds from "../elm/App/Feeds.elm"
import NewFeed from "../elm/App/NewFeed.elm"

const Elm =
  { App:
    { Feeds: Feeds.App.Feeds,
      NewFeed: NewFeed.App.NewFeed
    }
  }

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

class App {
  static mountElmModules() {
    const nodes = document.querySelectorAll("[data-elm-module]")

    for(const node of nodes) {
      // The module name may be `App` or `App.Feeds`. `modulePath` would be
      // ["App"] or ["App", "Feeds"], then.
      const moduleName = node.dataset.elmModule
      const modulePath = moduleName.split(".")
      const elmModule  = modulePath.reduce(
        (acc, part) => acc[part],
        Elm)

      const params = JSON.parse(node.dataset.elmParams) || {}

      if(elmModule != undefined) {
        elmModule.embed(node, params)
      } else {
        console.error(`No module named ‘${moduleName}’ could be found`)
      }
    }
  }
}

document.addEventListener("DOMContentLoaded", () => App.mountElmModules())
