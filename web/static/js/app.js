// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

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
      const modulePath = node.dataset.elmModule.split(".")
      const elmModule  = modulePath.reduce(
        (acc, part) => acc[part],
        Elm)

      const params = JSON.parse(node.dataset.elmParams) || {}

      if(elmModule != undefined) {
        elmModule.embed(node, params)
      }
    }
  }
}

document.addEventListener("DOMContentLoaded", () => App.mountElmModules())
