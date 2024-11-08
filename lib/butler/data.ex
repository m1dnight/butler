defmodule Butler.Data do
  alias Butler.Repo
  import Ecto.Query

  def last_n_messages(n \\ 25) do
    from(m in Butler.Plugins.Logger, order_by: [desc: :inserted_at])
    |> limit(^n)
    |> Repo.all()
  end

  def karma_top(n \\ 10) do
    Butler.Storage.load_state(Butler.Plugins.Karma)
    |> Map.get(:value, %{})
    |> Enum.into([])
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(n)
  end

  def karma_bottom(n \\ 10) do
    Butler.Storage.load_state(Butler.Plugins.Karma)
    |> Map.get(:value, %{})
    |> Enum.into([])
    |> Enum.sort_by(&elem(&1, 1), :asc)
    |> Enum.take(n)
  end

  def most_active(n \\ 10) do
    q =
      from m in Butler.Plugins.Logger,
        select: [m.from, count(m.from)],
        group_by: m.from,
        order_by: [desc: count(m.from)],
        limit: ^n

    Repo.all(q)
  end

  def average_messages_per_day() do
    count_per_day =
      from m in Butler.Plugins.Logger,
        select: %{count: count(m.id)},
        group_by: fragment("STRFTIME('%d-%m-%Y', ?)", m.inserted_at)

    q = from m in subquery(count_per_day), select: avg(m.count)
    Repo.one(q)
  end

  def known_users() do
    q =
      from m in Butler.Plugins.Logger,
        select: %{from: m.from},
        distinct: true

    Repo.aggregate(q, :count, :from)
  end

  def average_message_length() do
    q =
      from m in Butler.Plugins.Logger,
        select: avg(fragment("length(?)", m.content))

    Repo.one(q)
  end

  def most_active_day() do
    count_per_day =
      from m in Butler.Plugins.Logger,
        select: %{count: count(m.id), day: fragment("STRFTIME('%d-%m-%Y', ?)", m.inserted_at)},
        group_by: fragment("STRFTIME('%d-%m-%Y', ?)", m.inserted_at)

    q = from m in subquery(count_per_day), select: [max(m.count), m.day]

    case Repo.one(q) do
      [nil, nil] ->
        nil

      [count, day] ->
        {count, Timex.parse!(day, "{D}-{0M}-{YYYY}")}
    end
  end
end
