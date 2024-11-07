defmodule ButlerWeb.ChatLog do
  use Phoenix.Component

  use Gettext, backend: ButlerWeb.Gettext

  attr :id, :string
  attr :sender, :string, required: true
  attr :timestamp, DateTime, required: true
  attr :content, :string, required: true

  def message(assigns) do
    ~H"""
    <div class="message font-mono">
      <div class="timestamp mr-2 text-sm">
        <%= @timestamp |> DateTime.to_time() |> Time.truncate(:second) |> Time.to_iso8601() %>
      </div>
      <div
        class="name"
        style={"color: ##{:crypto.hash(:md5, @sender) |> :binary.bin_to_list |> Enum.take(3) |> :binary.list_to_bin |> Base.encode16}"}
      >
        <%= @sender %>
      </div>
      <div class="content">
        <%= @content %>
      </div>
    </div>
    """
  end

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def panel(assigns) do
    ~H"""
    <div class="panel">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def row(assigns) do
    ~H"""
    <div class="row">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
