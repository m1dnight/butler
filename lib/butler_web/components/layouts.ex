defmodule ButlerWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ButlerWeb, :controller` and
  `use ButlerWeb, :live_view`.
  """
  use ButlerWeb, :html

  embed_templates "layouts/*"
end
