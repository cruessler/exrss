# 2024-12-03
# `LayoutView` was generated before Phoenix 1.7. Deleting this module when
# migrating to Phoenix 1.7 patterns resulted in errors similar to the following
# one in tests:
#
# ```
# ** (ArgumentError) no "app" html template defined for ExRssWeb.LayoutView
# (the module does not exist)
# ```
#
# It is kept around to keep existing code working and to keep the initial
# migration to LiveView small.
defmodule ExRssWeb.LayoutView do
  use ExRssWeb, :view
end
