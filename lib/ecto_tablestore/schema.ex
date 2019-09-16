defmodule EctoTablestore.Schema do
  @moduledoc ~S"""
  Defines a schema for Tablestore.

  Since the atomic increment may need to return the increased value, `EctoTablestore.Schema` module underlying uses `Ecto.Schema`,
  and automatically append all `:integer` field type with `read_after_writes: true` option by default.

  An Ecto schema is used to map any data source into an Elixir struct. The definition of the schema is
  possible through the API: `tablestore_schema/2`.

  `tablestore_schema/2` is typically used to map data from a persisted source, usually a Tablestore table,
  into Elixir structs and vice-versa. For this reason, the first argument of `tablestore_schema/2` is the
  source(table) name. Structs defined with `tablestore_schema/2` also contain a `__meta__` field with metadata holding
  the status of struct, for example, if it has bee built, loaded or deleted.

  Since Tablestore is a NoSQL database service, `embedded_schema/1` is not supported so far.

  ## About primary_key

  * primary_key supports `:id` (integer()) and `:binary_id` (binary())
  * `@primary_key` default to `false`
  * the first defined primary key is partition key
  * up to 4 primary key(s) (Tablestore product required)
  * up to 1 primary key with `autogenerate: true` option (Tablestore product required)

  ## Example

  ```elixir
  defmodule User do
    use EctoTablestore.Schema

    tablestore_schema "users" do
      field :outer_id, :binary_id, primary_key: true
      field :internal_id, :id, primary_key: true, autogenerate: true
      field :name, :string
      field :desc
    end
  end
  ```

  By default, if not explicitly set field type will process it as `:string` type.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import EctoTablestore.Schema, only: [tablestore_schema: 2]

      @primary_key false
    end
  end

  defmacro tablestore_schema(source, do: block) do
    block = check_block(block)

    quote do
      Ecto.Schema.schema(unquote(source), do: unquote(block))
    end
  end

  defp check_block({:__block__, info, fields}) do
    {:__block__, info, supplement_fields(fields, [])}
  end

  defp supplement_fields([], prepared) do
    Enum.reverse(prepared)
  end

  defp supplement_fields(
         [{defined_macro, field_line, [field_name, :integer]} | rest_fields],
         prepared
       ) do
    update = {
      defined_macro,
      field_line,
      [
        field_name,
        {:__aliases__, field_line, [:EctoTablestore, :Integer]},
        [read_after_writes: true]
      ]
    }

    supplement_fields(rest_fields, [update | prepared])
  end

  defp supplement_fields(
         [{defined_macro, field_line, [field_name, :integer, opts]} | rest_fields],
         prepared
       ) do
    update = {
      defined_macro,
      field_line,
      [
        field_name,
        {:__aliases__, field_line, [:EctoTablestore, :Integer]},
        Keyword.put(opts, :read_after_writes, true)
      ]
    }

    supplement_fields(rest_fields, [update | prepared])
  end

  defp supplement_fields(
         [
           {defined_macro, field_line,
            [field_name, {:__aliases__, line, [:EctoTablestore, :Integer]}]}
           | rest_fields
         ],
         prepared
       ) do
    update = {
      defined_macro,
      field_line,
      [field_name, {:__aliases__, line, [:EctoTablestore, :Integer]}, [read_after_writes: true]]
    }

    supplement_fields(rest_fields, [update | prepared])
  end

  defp supplement_fields(
         [
           {defined_macro, field_line,
            [field_name, {:__aliases__, line, [:EctoTablestore, :Integer]}, opts]}
           | rest_fields
         ],
         prepared
       ) do
    update = {
      defined_macro,
      field_line,
      [
        field_name,
        {:__aliases__, line, [:EctoTablestore, :Integer]},
        Keyword.put(opts, :read_after_writes, true)
      ]
    }

    supplement_fields(rest_fields, [update | prepared])
  end

  defp supplement_fields([{defined_macro, field_line, field_info} | rest_fields], prepared) do
    supplement_fields(rest_fields, [{defined_macro, field_line, field_info} | prepared])
  end
end
